defmodule Mix.Tasks.Train do
  use Mix.Task

  @requirements ["app.start"]

  alias Digits

  def run(_) do
    {images, labels} = load_mnist()

    images =
      images
      |> Digits.Model.transform_images()
      |> Nx.to_batched(32)
      |> Enum.to_list()

    labels =
     labels
     |> Digits.Model.transform_labels()
     |> Nx.to_batched(32)
     |> Enum.to_list()

    data = Enum.zip(images, labels)

    training_count = floor(0.8 * Enum.count(data))
    validation_count = floor(0.2 * training_count)

    {training_data, test_data} = Enum.split(data, training_count)
    {validation_data, training_data} = Enum.split(training_data, validation_count)

    model = Digits.Model.new({1, 28, 28})

    Mix.Shell.IO.info("training...")

    state = Digits.Model.train(model, training_data, validation_data)

    Mix.Shell.IO.info("testing...")

    Digits.Model.test(model, state, test_data)

    Digits.Model.save!(model, state)

    :ok
  end

  defp load_mnist() do
    if !File.exists?(path()) do
      save_mnist()
    end

    load!()
  end

  defp save_mnist do
    Digits.Model.download()
    |> save!()
  end

  defp save!(data) do
    contents = :erlang.term_to_binary(data)

    File.write!(path(), contents)
  end

  defp load! do
    path()
    |> File.read!()
    |> :erlang.binary_to_term()
  end

  defp path do
    Path.join(Application.app_dir(:digits, "priv"), "mnist.axon")
  end
end
