import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list

pub type JsonValue {
  JsonArray(items: List(JsonValue))
  JsonString(value: String)
  JsonInt(value: Int)
  JsonFloat(value: Float)
  JsonBool(value: Bool)
  JsonObject(fields: List(#(String, JsonValue)))
  JsonNull
}

pub fn decoder() -> Decoder(JsonValue) {
  decode.one_of(decode.map(decode.string, JsonString), or: [
    decode.map(decode.int, JsonInt),
    decode.map(decode.float, JsonFloat),
    decode.map(decode.bool, JsonBool),
    decode.map(decode.list(decode.recursive(decoder)), JsonArray),
    decode.map(decode.dict(decode.string, decode.recursive(decoder)), fn(d) {
      JsonObject(dict.to_list(d))
    }),
  ])
}

pub fn to_json(value: JsonValue) -> Json {
  case value {
    JsonString(value:) -> json.string(value)
    JsonInt(value:) -> json.int(value)
    JsonFloat(value:) -> json.float(value)
    JsonBool(value:) -> json.bool(value)
    JsonNull -> json.null()
    JsonObject(fields:) ->
      json.object(list.map(fields, fn(p) { #(p.0, to_json(p.1)) }))
    JsonArray(items:) -> json.array(items, fn(item) { to_json(item) })
  }
}
