class GrowthCalculator
  def initialize(values, position)
    @values = values
    @position = position
  end

  def call
    previous, current = values[position-1..position]

    return nil if current == 0

    (current - previous).to_f / previous
  end

  private

    attr_reader :values, :position
end
