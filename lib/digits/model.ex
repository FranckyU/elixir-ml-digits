defmodule Digits.Model do
  @moduledoc """
  The Digits Machine Learning model
  """

  require Axon

  def download do
    Scidata.MNIST.download()
  end

  def transform_images({binary, type, shape}) do
    binary
    |> Nx.from_binary(type)
    |> Nx.reshape(shape)
    |> Nx.divide(255)
  end

  def transform_labels({binary, type, _}) do
    binary
    |> Nx.from_binary(type)
    |> Nx.new_axis(-1)
    |> Nx.equal(Nx.tensor(Enum.to_list(0..9)))
  end

  def new({channels, height, width}) do
    Axon.input("input_0", shape: {nil, channels, height, width})
    |> Axon.flatten()
    |> Axon.dense(128, activation: :relu)
    |> Axon.dense(10, activation: :softmax)
  end

  def train(model, training_data, validation_data) do
    model
    |> Axon.Loop.trainer(:categorical_cross_entropy, Axon.Optimizers.adam(0.01))
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.validate(model, validation_data)
    |> Axon.Loop.run(training_data, %{}, comṕiler: EXLA, epochs: 10)
  end

  def test(model, state, test_data) do
    model
    |> Axon.Loop.evaluator()
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(test_data, state)
  end

  def save!(model, state) do
    contents = Axon.serialize(model, state)

    File.write!(path(), contents)
  end

  def load! do
    path()
    |> File.read!()
    |> Axon.deserialize()
  end

  def path do
    Path.join(Application.app_dir(:digits, "priv"), "model.axon")
  end

  def predict(path) do
    mat = Evision.imread(path, flags: Evision.Constant.cv_IMREAD_GRAYSCALE())
    mat = Evision.resize(mat, {28, 28})

    data =
      Evision.Mat.to_nx(mat)
      |> Nx.reshape({1, 28, 28})
      |> List.wrap()
      |> Nx.stack()
      |> Nx.backend_transfer()

    {model, state} = load!()

    model
    |> Axon.predict(state, data)
    |> Nx.argmax()
    |> Nx.to_number()
  end
end
