import gleam/json
import json_value.{
  type JsonValue, JsonArray, JsonBool, JsonFloat, JsonInt, JsonObject,
  JsonString,
}

fn round_trip(value: JsonValue) -> Result(JsonValue, json.DecodeError) {
  value
  |> json_value.to_json
  |> json.to_string
  |> echo
  |> json.parse(json_value.decoder())
}

pub fn round_trip_int_test() {
  assert round_trip(JsonInt(42)) == Ok(JsonInt(42))
}

pub fn round_trip_complex_test() {
  let complex =
    JsonObject([
      #(
        "tree",
        JsonArray([
          JsonInt(1),
          JsonFloat(2.5),
          JsonBool(True),
          JsonString("leaf"),
          JsonArray([
            JsonInt(-7),
            JsonObject([
              #(
                "nested",
                JsonArray([
                  JsonBool(False),
                  JsonFloat(0.0),
                  JsonObject([
                    #("deep", JsonString("bottom")),
                  ]),
                ]),
              ),
            ]),
          ]),
          JsonArray([]),
        ]),
      ),
    ])

  assert round_trip(complex) == Ok(complex)
}

pub fn encode_string_test() {
  let ecoded_string =
    "Hi"
    |> JsonString
    |> json_value.to_json
    |> json.to_string

  assert ecoded_string == "\"Hi\""
}
