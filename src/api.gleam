import gleam/dynamic/decode.{type Decoder}
import gleam/http.{Post}
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json.{type Json}
import gleam/result
import json_value.{type JsonValue}

pub type Role {
  User
  Assistant
}

pub type ContentBlock {
  TextBlock(text: String)
  ToolUseBlock(id: String, name: String, input: JsonValue)
  ToolResultBlock(tool_use_id: String, content: String, is_error: Bool)
}

pub type Message {
  Message(role: Role, content: List(ContentBlock))
}

pub type StopReason {
  EndTurn
  MaxTokens
  ToolUseStop
  OtherStop(String)
}

pub type ApiResponse {
  ApiResponse(content: List(ContentBlock), stop_reason: StopReason)
}

pub type ToolDef {
  ToolDef(name: String, description: String, input_schema: Json)
}

pub type Client {
  Client(api_key: String, base_url: String)
}

pub fn create_message(
  client: Client,
  model: String,
  system_prompt: String,
  messages: List(Message),
  tools: List(ToolDef),
  max_tokens: Int,
) -> Result(ApiResponse, String) {
  let body = 
    json.object([
      #("model", json.string(model)),
      #("max_tokens", json.int(max_tokens)),
      #("system", json.string(system_prompt)),
      #("messages", json.array(messages, encode_message)),
      #("tools", json.array(tools, encode_tool)),
    ])
    |> json.to_string
    
    use base <- result.try(
      request.to(client.base_url <> "/v1/messages")
      |> result.replace_error("Invalid base URL"),
    )

    let req =
      base
      |> request.set_method(Post)
      |> request.set_header("content-type", "application/json")
      |> request.set_header("x-api-key", client.api_key)
      |> request.set_header("anthropic-version", "2023-06-01")
      |> request.set_body(body)

    use resp <- result.try(
      httpc.send(req)
      |> result.map_error(fn(_) { "HTTP transport error" })
    )

    case resp.status {
      200 ->
        json.parse(resp.body, response_decoder())
        |> result.map_error(fn(_) { "Failed to decode API response" })
      code -> Error("API error " <> int.to_string(code) <> ": " <> resp.body)
    }
}

fn block_decoder() -> Decoder(ContentBlock) {
  use kind <- decode.field("type", decode.string)
  case kind {
    "text" -> {
      use text <- decode.field("text", decode.string)
      decode.success(TextBlock(text:))
    }
    "tool_use" -> {
      use id <- decode.field("id", decode.string)
      use name <- decode.field("name", decode.string)
      use input <- decode.field("input", json_value.decoder())
      decode.success(ToolUseBlock(id:, name:, input:))
    }
    other -> decode.failure(TextBlock(text: ""), "ContentBlock: " <> other)
  }
}

fn response_decoder() -> Decoder(ApiResponse) {
  use content <- decode.field("content", decode.list(block_decoder()))
  use stop_reason <- decode.field("stop_reason", stop_reason_decoder())
  decode.success(ApiResponse(content:, stop_reason:))
}

fn encode_message(message: Message) -> Json {
  let role = case message.role {
    User -> "user"
    Assistant -> "assistant"
  }

  json.object([
    #("role", json.string(role)),
    #("content", json.array(message.content, encode_block))
  ])
}

fn encode_block(block: ContentBlock) -> Json {
  case block {
    TextBlock(text:) -> 
      json.object([
        #("type", json.string("text")),
        #("text", json.string(text)),
      ])
    ToolUseBlock(id:, name:, input:) -> 
      json.object([
        #("type", json.string("tool_use")),
        #("id", json.string(id)),
        #("name", json.string(name)),
        #("input", json_value.to_json(input)),
      ])
    ToolResultBlock(tool_use_id:, content:, is_error:) ->
      json.object([
        #("type", json.string("tool_result")),
        #("tool_use_id", json.string(tool_use_id)),
        #("content", json.string(content)),
        #("is_error", json.bool(is_error)),
      ])
  }
}

fn encode_tool(tool: ToolDef) -> Json {
  json.object([
    #("name", json.string(tool.name)),
    #("description", json.string(tool.description)),
    #("input_schema", tool.input_schema),
  ])
}

fn stop_reason_decoder() -> Decoder(StopReason) {
  use reason <- decode.then(decode.string)
  case reason {
    "end_turn" -> decode.success(EndTurn)
    "max_tokens" -> decode.success(MaxTokens)
    "tool_use" -> decode.success(ToolUseStop)
    other -> decode.success(OtherStop(other))
  }
}