defimpl String.Chars, for: PID do
  def to_string(pid) do
    info = Process.info(pid)
    name = info[:registered_name]

    "#{name}-#{inspect(pid)}"
  end
end
