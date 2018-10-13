#
#  Created by Boyd Multerer on 2017-11-13.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Hash do
  @moduledoc """
  Ssimple functions to load a file, following the hashing rules
  """
  #  import IEx

  @hash_types [:sha, :sha224, :sha256, :sha384, :sha512, :ripemd160]
  @default_hash :sha

  # ===========================================================================
  defmodule Error do
    @moduledoc false

    defexception message: "Hash check failed"
  end

  # --------------------------------------------------------
  @spec valid_hash_types() :: [:ripemd160 | :sha | :sha224 | :sha256 | :sha384 | :sha512, ...]
  def valid_hash_types, do: @hash_types
  # --------------------------------------------------------
  @spec valid_hash_type?(any()) :: boolean()
  def valid_hash_type?(hash_type), do: Enum.member?(@hash_types, hash_type)
  # --------------------------------------------------------
  @spec valid_hash_type!(any()) :: any() | no_return
  def valid_hash_type!(hash_type) do
    case Enum.member?(@hash_types, hash_type) do
      true ->
        hash_type

      false ->
        msg = "Invalid hash type: #{hash_type}\r\n" <> "Must be one of: #{inspect(@hash_types)}"
        raise Error, message: msg
    end
  end

  # --------------------------------------------------------
  @spec binary(any(), any()) :: {:error, :invalid_hash_type} | {:ok, binary()}
  def binary(data, hash_type) do
    case valid_hash_type?(hash_type) do
      true -> {:ok, hash_type |> :crypto.hash(data) |> Base.url_encode64(padding: false)}
      false -> {:error, :invalid_hash_type}
    end
  end

  def binary!(data, hash_type) do
    valid_hash_type!(hash_type)
    |> :crypto.hash(data)
    |> Base.url_encode64(padding: false)
  end

  # --------------------------------------------------------
  def file(path, hash_type) do
    do_compute_file(
      path,
      hash_type,
      valid_hash_type?(hash_type)
    )
  end

  def file!(path, hash_type) do
    # start the hash context
    hash_context =
      valid_hash_type!(hash_type)
      |> :crypto.hash_init()

    # stream the file into the hash
    File.stream!(path, [], 2048)
    |> Enum.reduce(hash_context, &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.url_encode64(padding: false)
  end

  defp do_compute_file(_, _, false), do: {:error, :invalid_hash_type}

  defp do_compute_file(path, hash_type, true) do
    # start the hash context
    hash_context = :crypto.hash_init(hash_type)

    # since there is no File.stream option, only File.stream!, catch the error
    try do
      # stream the file into the hash
      hash =
        File.stream!(path, [], 2048)
        |> Enum.reduce(hash_context, &:crypto.hash_update(&2, &1))
        |> :crypto.hash_final()
        |> Base.url_encode64(padding: false)

      {:ok, hash}
    rescue
      err ->
        :crypto.hash_final(hash_context)

        case err do
          %{reason: reason} -> {:error, reason}
          _ -> {:error, :hash}
        end
    end
  end

  # --------------------------------------------------------
  def verify(data, hash, hash_type) do
    case binary(data, hash_type) do
      {:ok, ^hash} -> {:ok, data}
      _ -> {:error, :hash_failure}
    end
  end

  # --------------------------------------------------------
  def verify!(data, hash, hash_type) do
    case binary!(data, hash_type) == hash do
      true -> data
      false -> raise Error
    end
  end

  # --------------------------------------------------------
  def verify_file(path_data), do: path_params(path_data) |> do_verify_file()

  defp do_verify_file({path, hash, hash_type}) do
    case file(path, hash_type) do
      {:ok, computed_hash} ->
        case computed_hash == hash do
          true -> {:ok, hash}
          false -> {:error, :hash_failure}
        end

      err ->
        err
    end
  end

  # --------------------------------------------------------
  def verify_file!(path_data), do: path_params(path_data) |> do_verify_file!()

  defp do_verify_file!({path, hash, hash_type}) do
    case file!(path, hash_type) == hash do
      true -> hash
      false -> raise Error
    end
  end

  # --------------------------------------------------------
  def from_path(path) do
    path
    |> String.split(".")
    |> List.last()
  end

  # --------------------------------------------------------
  def path_params(path)

  def path_params(path) when is_bitstring(path) do
    hash = from_path(path)
    path_params({path, hash, @default_hash})
  end

  def path_params({path, hash_type}) when is_atom(hash_type) do
    hash = from_path(path)
    path_params({path, hash, hash_type})
  end

  def path_params({path_or_data, hash}), do: path_params({path_or_data, hash, @default_hash})

  def path_params({path_or_data, hash, hash_type})
      when is_binary(path_or_data) and is_bitstring(hash) and is_atom(hash_type) do
    {path_or_data, hash, valid_hash_type!(hash_type)}
  end

  def path_params(path_or_data, hash_or_type), do: path_params({path_or_data, hash_or_type})
  def path_params(path_or_data, hash, hash_type), do: path_params({path_or_data, hash, hash_type})
end
