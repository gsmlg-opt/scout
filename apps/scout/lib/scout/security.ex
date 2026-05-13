defmodule Scout.Security do
  @moduledoc """
  URL boundary checks for Scout fetch requests.
  """

  def validate_url(url, settings) when is_binary(url) do
    uri = URI.parse(url)

    with :ok <- validate_scheme(uri, settings),
         :ok <- validate_host(uri, settings) do
      :ok
    end
  end

  def validate_url(_url, _settings), do: error(:invalid_url, "url must be a string", false)

  defp validate_scheme(%URI{scheme: scheme}, settings) do
    allowed = settings["security"]["allowed_schemes"]

    if scheme in allowed do
      :ok
    else
      error(:unsupported_protocol, "only HTTP and HTTPS URLs are supported", false)
    end
  end

  defp validate_host(%URI{host: host}, settings) when is_binary(host) and host != "" do
    normalized = String.downcase(host)

    cond do
      normalized in ["localhost", "localhost.localdomain"] ->
        error(:blocked_target, "localhost targets are blocked", false)

      String.ends_with?(normalized, ".localhost") ->
        error(:blocked_target, "localhost targets are blocked", false)

      blocked_literal_ip?(normalized, settings) ->
        error(:blocked_target, "private network targets are blocked", false)

      true ->
        :ok
    end
  end

  defp validate_host(_uri, _settings), do: error(:invalid_url, "url host is required", false)

  defp blocked_literal_ip?(host, settings) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, address} ->
        Enum.any?(settings["security"]["blocked_cidrs"], &cidr_contains?(&1, address))

      {:error, :einval} ->
        false
    end
  end

  defp cidr_contains?(cidr, address) do
    with [network, prefix] <- String.split(cidr, "/"),
         {prefix, ""} <- Integer.parse(prefix),
         {:ok, network_address} <- :inet.parse_address(String.to_charlist(network)),
         {network_int, bits} <- ip_to_integer(network_address),
         {address_int, ^bits} <- ip_to_integer(address),
         true <- prefix >= 0 and prefix <= bits do
      divisor = Integer.pow(2, bits - prefix)
      div(network_int, divisor) == div(address_int, divisor)
    else
      _ -> false
    end
  end

  defp ip_to_integer({_, _, _, _} = address) do
    integer =
      address
      |> Tuple.to_list()
      |> Enum.reduce(0, fn part, acc -> acc * 256 + part end)

    {integer, 32}
  end

  defp ip_to_integer(address) when tuple_size(address) == 8 do
    integer =
      address
      |> Tuple.to_list()
      |> Enum.reduce(0, fn part, acc -> acc * 65_536 + part end)

    {integer, 128}
  end

  defp error(type, message, retryable) do
    {:error, %{type: to_string(type), message: message, retryable: retryable}}
  end
end
