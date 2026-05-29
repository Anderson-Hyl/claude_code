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
  ToolUseBlock(id: String, name: String, iput: JsonValue)
  ToolResultBlock(tool_use_id: String, content: String, is_error: Bool)
}
