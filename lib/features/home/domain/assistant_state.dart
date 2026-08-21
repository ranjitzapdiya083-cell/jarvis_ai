/// Mirrors spec section 4 — the assistant's finite set of visible states.
enum AssistantState {
  idle,
  listening,
  processing,
  speaking,
  executing,
  success,
  error,
  permissionRequired,
}
