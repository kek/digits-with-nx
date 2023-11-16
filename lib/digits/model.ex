defmodule Digits.Model do
  @moduledoc """
  The Digits Machine Learning Model
  """

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

  def whatever() do
    {images, labels} = Digits.Model.download()

    batch_size = 32

    images =
      images
      |> Digits.Model.transform_images()
      |> Nx.to_batched(batch_size)
      |> Enum.to_list()

    labels =
      labels
      |> Digits.Model.transform_labels()
      |> Nx.to_batched(batch_size)
      |> Enum.to_list()

    data =
      Enum.zip(images, labels)

    training_count = floor(0.8 * Enum.count(data))
    validation_count = floor(0.2 * training_count)

    {training_data, test_data} = Enum.split(data, training_count)
    {validation_data, training_data} = Enum.split(training_data, validation_count)

    {training_data, validation_data, test_data}
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
    |> Axon.Loop.run(training_data, %{}, compiler: EXLA, epochs: 10)
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
end
