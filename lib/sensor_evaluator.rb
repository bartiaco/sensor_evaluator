require "Date"
require "sensor_evaluator/version"

class SensorEvaluator
  attr_accessor :log_contents_string
  attr_reader :processed_reference
  attr_reader :processed_sensors

  def initialize(log_contents_string = "")
    @log_contents_string = log_contents_string
    @processed_sensors = []
  end

  class TestReference
    # Recommendation: Have reference line includes labels for attributes being measured.
    # This will allow new attributes to be easily added with minimal code changes

    attr_reader :temperature, :humidity, :monoxide

    def initialize(test_reference_row)
      @temperature = test_reference_row.split[1]
      @humidity = test_reference_row.split[2]
      @monoxide = test_reference_row.split[3]
    end
  end

  class Sensor
    attr_reader :model, :name
    attr_accessor :sensor_readings, :test_reference

    def initialize(sensor_row = "")
      @model = sensor_row.split[0] || ""
      @name = sensor_row.split[1] || ""
      @sensor_readings = []
    end

    def sum_sensor_reading
      @sensor_readings.map { |reading| Float(reading.value) }.sum
    end

    def mean_sensor_reading
      sum_sensor_reading / @sensor_readings.length
    end

    def variance_sensor_reading
      values = @sensor_readings.map { |reading| Float(reading.value ) }
      values.map { |value| (value - mean_sensor_reading )**2 }.sum / @sensor_readings.length
    end

    def standard_deviation_sensor_reading
      Math.sqrt(variance_sensor_reading)
    end

    def report
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def valid?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end
  end

  class Thermometer < Sensor
    MODEL_NAME_STRING = 'thermometer'

    def report
      return false unless @test_reference && @sensor_readings.length > 0

      report = { name => "precise" }

      if (mean_sensor_reading - Float(@test_reference.temperature)).abs <= 0.5
        if standard_deviation_sensor_reading < 3
          report[name] = "ultra precise"
        elsif standard_deviation_sensor_reading < 5
          report[name] = "very precise"
        end
      end

      return report
    end

    def valid?
      (@model == MODEL_NAME_STRING) && (@name.length > 0)
    end
  end

  class Humidity < Sensor
    MODEL_NAME_STRING = 'humidity'

    def valid?
      (@model == MODEL_NAME_STRING) && (@name.length > 0)
    end

    def report
      return false unless @test_reference && @sensor_readings.length > 0

      values = @sensor_readings.map { |reading| Float(reading.value) }

      if values.any? { |value| (value - Float(@test_reference.humidity)).abs > 1 }
        return { name => "discard" }
      else
        return { name => "keep" }
      end
    end
  end

  class Monoxide < Sensor
    MODEL_NAME_STRING = 'monoxide'

    def valid?
      (@model == MODEL_NAME_STRING) && (@name.length > 0)
    end

    def report
      return false unless @test_reference && @sensor_readings.length > 0

      values = @sensor_readings.map { |reading| Integer(reading.value) }

      if values.any? { |value| (value - Integer(@test_reference.monoxide)).abs > 3 }
      return { name => "discard" }
    else
      return { name => "keep" }
    end
    end
  end

  class SensorData
    # Recommendation: Have data point line include labels for attributes being measured.
    # This will allow new attributes to be easily added with minimal code changes
    # could also easily support sensors with multiple data points
    # Example: TIMESTAMP humidity:5 temperature:83.6

    attr_reader :timestamp, :value
    def initialize(sensor_data_row = "")
      @timestamp = sensor_data_row.split[0] || ""
      @value = sensor_data_row.split[1] || ""
    end

    def valid?
      begin
        !!Date.parse(@timestamp) && !!Float(@value)
      rescue
        false
      end
    end
  end

  def report
    process_log_contents
    @processed_sensors.map(&:report).inject(&:merge) || {}
  end

  private

  def process_log_contents
    log_array = log_contents_rows
    @processed_sensors = []

    return false if log_array.length < 1

    @processed_reference = TestReference.new(log_array.shift)

    log_array.each do |log_row|
      current_strategy = strategies(log_row).detect(&:valid?)
      if current_strategy.kind_of?(Sensor)
        current_strategy.test_reference = @processed_reference
        @processed_sensors << current_strategy
      elsif current_strategy.kind_of?(SensorData)
        @processed_sensors.last.sensor_readings << current_strategy
      end
    end
  end

  def strategies(log_row)
    [
      Thermometer.new(log_row),
      Humidity.new(log_row),
      Monoxide.new(log_row),
      SensorData.new(log_row),
    ]
  end

  def log_contents_rows
    log_contents_string.split("\n")
  end
end
















# def process_row(data_row, index, current_thing = nil)
#   data
#   if current_thing.nil?
#     current_thing = Thing.new(data_row.split.first, data_row.split.last)
#   end

# end








