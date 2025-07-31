"""
Simple LangGraph agent example
"""

from typing import Annotated, Literal, TypedDict
from langchain_core.messages import HumanMessage
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages


class State(TypedDict):
    # Messages have the type "list[BaseMessage]"
    messages: Annotated[list, add_messages]


def chatbot(state: State):
    return {"messages": [f"Hello! You said: {state['messages'][-1].content}"]}


def route_message(state: State) -> Literal["chatbot", END]:
    """Route to chatbot or end."""
    messages = state.get("messages", [])
    if messages and messages[-1].content.lower() == "quit":
        return END
    return "chatbot"


# Build the graph
graph_builder = StateGraph(State)
graph_builder.add_node("chatbot", chatbot)
graph_builder.add_edge(START, "chatbot")
graph_builder.add_conditional_edges("chatbot", route_message)

# Compile the graph
graph = graph_builder.compile()
