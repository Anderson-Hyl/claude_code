
import api
import gleam/list
import gleam/result

pub type AgentState {
  AgentState(
    client: api.Client,
    model: String,
    system_prompt: String,
    messages: List(api.Message),
    cwd: String,
    config: LoopConfig,
    todos: List(TodoItem),
    idle_turns: Int,
    skills: SkillLoader,
    task_store: TaskStore,
    background: Subject(background.Message),
  )
}

pub fn run(
  state: AgentState,
  query: String,
) -> Result(#(String, AgentState), String) {
  let message = api.Message(role: api.User, content: [api.TextBlock(text:query)])
  let state = AgentState(..state, messages: list.append(state.messages, [message]))
  loop(state, 0)
}

fn loop(
  state: AgentState,
  iteration: Int,
) -> Result(#(String, AgentState), String) {
  case iteration >= state.config.max_iterations {
    True -> Ok(#("(stopped: iteration cap reached)", state))
    False -> {
      let state = compact_step(state)
      use response <- result.try(
        api.create_message(
          state.client,
          state.model,
          state.system_prompt,
          state.messages,
          tool_defs(state.config),
          4096
          )
      )

      let reply = api.Message(role: api.Assistant, content: response.content)
      let state = AgentState(..state, messages: list.append(state.messages, [reply]))
      
    }
  }
}

fn compact_step(state: AgentState) -> AgentState {
  todo
}