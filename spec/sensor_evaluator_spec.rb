RSpec.describe SensorEvaluator do
  let(:log_contents_string) { File.read(File.join(File.dirname(__FILE__), "support", "provided_test_samples.log")) }

  # subject(:sensor_evaluator) { SensorEvaluator.new }
  it "has a version number" do
    expect(SensorEvaluator::VERSION).not_to be nil
  end

  describe "#log_contents_string" do
    it "returns an empty string by default" do
      expect(SensorEvaluator.new.log_contents_string).to eq("")
    end

    it "returns the initialized value when one was passed in" do
      expect(SensorEvaluator.new(log_contents_string).log_contents_string).to eq(log_contents_string)
    end
  end

  # it "does stuff" do
  #   sensor_evaluator = SensorEvaluator.new(log_contents_string)
  #   sensor_evaluator.process_log_contents
  #   puts sensor_evaluator.processed_logs_report
  # end

  describe "#report" do
    it "should return an empty hash by default" do
      expect(SensorEvaluator.new.report).to eq({})
    end

    context "When evaluating the provided_test_samples.log" do
      let(:sensor_evaluator) { SensorEvaluator.new(log_contents_string) }

      it "returns the expected values for the report" do
        expect(sensor_evaluator.report).to eq(
          {
            "temp-1"=>"precise",
            "temp-2"=>"ultra precise",
            "hum-1"=>"keep",
            "hum-2"=>"discard",
            "mon-1"=>"keep",
            "mon-2"=>"discard",
          }
        )
      end
    end
  end
end

RSpec.describe SensorEvaluator::TestReference do
  describe '#temperature' do
    it 'responds to model' do
      expect(SensorEvaluator::TestReference.new('reference 70.0 45.0 6')).to respond_to(:temperature)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::TestReference.new('reference 70.0 45.0 6').temperature).to eq('70.0')
    end
  end

  describe '#humidity' do
    it 'responds to model' do
      expect(SensorEvaluator::TestReference.new('reference 70.0 45.0 6')).to respond_to(:humidity)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::TestReference.new('reference 70.0 45.0 6').humidity).to eq('45.0')
    end
  end


  describe '#monoxide' do
    it 'responds to model' do
      expect(SensorEvaluator::TestReference.new('reference 70.0 45.0 6')).to respond_to(:monoxide)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::TestReference.new('reference 70.0 45.0 6').monoxide).to eq('6')
    end
  end
end

RSpec.describe SensorEvaluator::Sensor do
  describe '#model' do
    it 'responds to model' do
      expect(SensorEvaluator::Sensor.new).to respond_to(:model)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::Sensor.new("Somemodel Somename").model).to eq("Somemodel")
    end
  end

  describe '#name' do
    it 'responds to name' do
      expect(SensorEvaluator::Sensor.new).to respond_to(:name)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::Sensor.new("Somemodel Somename").name).to eq("Somename")
    end
  end

  describe '#valid?' do
    it 'raises a NotImplementedError' do
      expect {
        SensorEvaluator::Sensor.new("Somemodel Somename").valid?
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#report' do
    it 'raises a NotImplementedError' do
      expect {
        SensorEvaluator::Sensor.new("Somemodel Somename").report
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#mean_sensor_value' do
    before do
      @sensor = SensorEvaluator::Sensor.new('thermometer Therm1')
      @sensor.sensor_readings = [
        SensorEvaluator::SensorData.new('2007-04-05T22:04 1'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 2'),
        SensorEvaluator::SensorData.new('2007-04-05T22:04 3'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 4'),

      ]
    end
    it 'returns the mean value of all sensor readings' do
      expect(@sensor.mean_sensor_reading).to eq(2.5)
    end
  end

  describe '#sum_sensor_reading' do
    before do
      @sensor = SensorEvaluator::Sensor.new('thermometer Therm1')
      @sensor.sensor_readings = [
        SensorEvaluator::SensorData.new('2007-04-05T22:04 1.5'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 2'),
        SensorEvaluator::SensorData.new('2007-04-05T22:04 3'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 4'),

      ]
    end
    it 'returns the sum of all sensor readings' do
      expect(@sensor.sum_sensor_reading).to eq(10.5)
    end
  end

  describe '#variance_sensor_reading' do
    before do
      @sensor = SensorEvaluator::Sensor.new('thermometer Therm1')
      @sensor.sensor_readings = [
        SensorEvaluator::SensorData.new('2007-04-05T22:04 1'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 2'),
        SensorEvaluator::SensorData.new('2007-04-05T22:04 3'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 4'),

      ]
    end
    it 'returns the variance of all sensor readings' do
      expect(@sensor.variance_sensor_reading).to eq(1.25)
    end
  end

  describe '#standard_deviation_sensor_reading' do
    before do
      @sensor = SensorEvaluator::Sensor.new('thermometer Therm1')
      allow(@sensor).to receive(:variance_sensor_reading).and_return(9)
    end
    it 'returns the variance of all sensor readings' do
      expect(@sensor.standard_deviation_sensor_reading).to eq(3)
    end
  end
end

RSpec.describe SensorEvaluator::Thermometer do
  describe "MODEL_NAME_STRING" do
    it "returns thermometer" do
      expect(SensorEvaluator::Thermometer::MODEL_NAME_STRING).to eq('thermometer')
    end
  end

  describe "#valid?" do
    context "when the model is correct and a name is present" do
      before do
        @sensor = SensorEvaluator::Thermometer.new('thermometer Therm1')
      end

      it 'returns true' do
        expect(@sensor.valid?).to be true
      end
    end

    context "when the model is incorrect and a name is present" do
      before do
        @sensor = SensorEvaluator::Thermometer.new('thingamabobTherm1')
      end

      it 'returns false' do
        expect(@sensor.valid?).to be false
      end
    end

    context "when the model is correct and a name is blank" do
      before do
        @sensor = SensorEvaluator::Thermometer.new('thermometer')
      end

      it 'returns false' do
        expect(@sensor.valid?).to be false
      end
    end
  end

  describe "report" do
    before do
      @sensor = SensorEvaluator::Thermometer.new('thermometer Therm1')
      @test_reference = SensorEvaluator::TestReference.new('reference 70.0 45.0 6
      ')
      @sensor.test_reference = @test_reference
      @sensor.sensor_readings = [
        SensorEvaluator::SensorData.new('2007-04-05T22:04 71.2'),
        SensorEvaluator::SensorData.new('2007-04-05T22:06 70.2'),
      ]
    end

    context 'when the mean sensor reading is within 0.5deg and the standard deviation is less than 3' do
      before do
        allow(@sensor).to receive(:mean_sensor_reading).and_return(75)
        allow(@sensor).to receive(:standard_deviation_sensor_reading).and_return(2.8)
        allow(@test_reference).to receive(:temperature).and_return('75.5')
      end
      it 'is classified as ultra precise' do
        expect(@sensor.report).to eq({"Therm1" => "ultra precise"})
      end
    end
  
    context 'when the mean sensor reading is within 0.5deg and the standard deviation is less than 5' do
      before do
        allow(@sensor).to receive(:mean_sensor_reading).and_return(75)
        allow(@sensor).to receive(:standard_deviation_sensor_reading).and_return(4.8)
        allow(@test_reference).to receive(:temperature).and_return('75.5')
      end

      it 'is classified as very precise' do
        expect(@sensor.report).to eq({"Therm1" => "very precise"})
      end
    end

    context 'when the mean sensor reading is farther than 0.5deg' do
      before do
        allow(@sensor).to receive(:mean_sensor_reading).and_return(75)
        allow(@sensor).to receive(:standard_deviation_sensor_reading).and_return(4.8)
        allow(@test_reference).to receive(:temperature).and_return('76')
      end

      it 'is classified as precise' do
        expect(@sensor.report).to eq({"Therm1" => "precise"})
      end
    end

    context 'when the standard_deviation is greater than 5' do
      before do
        allow(@sensor).to receive(:mean_sensor_reading).and_return(75)
        allow(@sensor).to receive(:standard_deviation_sensor_reading).and_return(5.1)
        allow(@test_reference).to receive(:temperature).and_return('75.2')
      end

      it 'is classified as precise' do
        expect(@sensor.report).to eq({"Therm1" => "precise"})
      end
    end

    context 'when there is no test_reference' do
      before do
        @sensor.test_reference = nil
      end
  
      it 'returns false' do
        expect(@sensor.report).to be false
      end
    end

    context 'when there are no sensor_readings' do
      before do
        @sensor.sensor_readings = []
      end
      it 'returns false' do
        expect(@sensor.report).to be false
      end
    end
  end
end

RSpec.describe SensorEvaluator::Humidity do
  describe "MODEL_NAME_STRING" do
    it "returns humidity" do
      expect(SensorEvaluator::Humidity::MODEL_NAME_STRING).to eq('humidity')
    end
  end

  describe "#valid?" do
    context "when the model is correct and a name is present" do
      before do
        @sensor = SensorEvaluator::Humidity.new('humidity Hum1')
      end

      it 'returns true' do
        expect(@sensor.valid?).to be true
      end
    end

    context "when the model is incorrect and a name is present" do
      before do
        @sensor = SensorEvaluator::Humidity.new('thingamabob Hum1')
      end

      it 'returns false' do
        expect(@sensor.valid?).to be false
      end
    end

    context "when the model is correct and a name is blank" do
      before do
        @sensor = SensorEvaluator::Humidity.new('humidity')
      end

      it 'returns false' do
        expect(@sensor.valid?).to be false
      end
    end
  end

  describe "report" do
    before do
      @sensor = SensorEvaluator::Humidity.new('humidity Hum1')
      @test_reference = SensorEvaluator::TestReference.new('reference 70.0 45.0 6
      ')
      @sensor.test_reference = @test_reference
    end

    context 'when all of the sensor readings are within 1 percent of the reference' do
      before do
        @sensor.sensor_readings = [
          SensorEvaluator::SensorData.new('2007-04-05T22:04 44.5'),
          SensorEvaluator::SensorData.new('2007-04-05T22:06 45.5'),
        ]
        allow(@test_reference).to receive(:humidity).and_return('45.0')
      end
      it 'is classified as keep' do
        expect(@sensor.report).to eq({"Hum1" => "keep"})
      end
    end

    context 'when any sensor reading is farther than 1 percent from the refrence' do
      before do
        @sensor.sensor_readings = [
          SensorEvaluator::SensorData.new('2007-04-05T22:04 44.5'),
          SensorEvaluator::SensorData.new('2007-04-05T22:06 46.5'),
        ]
        allow(@test_reference).to receive(:humidity).and_return('45.0')
      end

      it 'is classified as discard' do
        expect(@sensor.report).to eq({"Hum1" => "discard"})
      end
    end

    context 'when there is no test_reference' do
      before do
        @sensor.test_reference = nil
      end
  
      it 'returns false' do
        expect(@sensor.report).to be false
      end
    end

    context 'when there are no sensor_readings' do
      before do
        @sensor.sensor_readings = []
      end
      it 'returns false' do
        expect(@sensor.report).to be false
      end
    end
  end
end

RSpec.describe SensorEvaluator::Monoxide do
  describe "MODEL_NAME_STRING" do
    it "returns monoxide" do
      expect(SensorEvaluator::Monoxide::MODEL_NAME_STRING).to eq('monoxide')
    end
  end

  describe "#valid?" do
    context "when the model is correct and a name is present" do
      before do
        @sensor = SensorEvaluator::Monoxide.new('monoxide Mon1')
      end

      it 'returns true' do
        expect(@sensor.valid?).to be true
      end
    end

    context "when the model is incorrect and a name is present" do
      before do
        @sensor = SensorEvaluator::Monoxide.new('thingamabob Mon1')
      end

      it 'returns false' do
        expect(@sensor.valid?).to be false
      end
    end

    context "when the model is correct and a name is blank" do
      before do
        @sensor = SensorEvaluator::Monoxide.new('monoxide')
      end

      it 'returns false' do
        expect(@sensor.valid?).to be false
      end
    end
  end

  describe "report" do
    before do
      @sensor = SensorEvaluator::Monoxide.new('monoxide Mon1')
      @test_reference = SensorEvaluator::TestReference.new('reference 70.0 45.0 6
      ')
      @sensor.test_reference = @test_reference
    end

    context 'when all of the sensor readings are within 3ppm of the reference' do
      before do
        @sensor.sensor_readings = [
          SensorEvaluator::SensorData.new('2007-04-05T22:04 5'),
          SensorEvaluator::SensorData.new('2007-04-05T22:06 9'),
        ]
        allow(@test_reference).to receive(:monoxide).and_return('7')
      end
      it 'is classified as keep' do
        expect(@sensor.report).to eq({"Mon1" => "keep"})
      end
    end

    context 'when any sensor reading is farther than 3ppm from the refrence' do
      before do
        @sensor.sensor_readings = [
          SensorEvaluator::SensorData.new('2007-04-05T22:04 1'),
          SensorEvaluator::SensorData.new('2007-04-05T22:06 9'),
        ]
        allow(@test_reference).to receive(:monoxide).and_return('7')
      end

      it 'is classified as discard' do
        expect(@sensor.report).to eq({"Mon1" => "discard"})
      end
    end

    context 'when there is no test_reference' do
      before do
        @sensor.test_reference = nil
      end
  
      it 'returns false' do
        expect(@sensor.report).to be false
      end
    end

    context 'when there are no sensor_readings' do
      before do
        @sensor.sensor_readings = []
      end
      it 'returns false' do
        expect(@sensor.report).to be false
      end
    end
  end
end

RSpec.describe SensorEvaluator::SensorData do
  describe '#timestamp' do
    it 'responds to timestamp' do
      expect(SensorEvaluator::SensorData.new).to respond_to(:timestamp)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::SensorData.new('2007-04-05T22:04 71.2').timestamp).to eq('2007-04-05T22:04')
    end
  end

  describe '#value' do
    it 'responds to value' do
      expect(SensorEvaluator::SensorData.new).to respond_to(:value)
    end

    it 'has value set via initializer' do
      expect(SensorEvaluator::SensorData.new("2007-04-05T22:04 71.2").value).to eq("71.2")
    end
  end

  describe "#valid?" do
    context "when the timestamp is correct and a value is present" do
      before do
        @sensor_data = SensorEvaluator::SensorData.new('2007-04-05T22:04 71.2')
      end

      it "returns true" do
        expect(@sensor_data.valid?).to be true
      end
    end

    context "when the timestamp is incorrect and a value is present" do
      before do
        @sensor_data = SensorEvaluator::SensorData.new('not_a_timestamp 71.2')
      end

      it "returns false" do
        expect(@sensor_data.valid?).to be false
      end
    end

    context "when the timestamp is correct and a value is blank" do
      before do
        @sensor_data = SensorEvaluator::SensorData.new('2007-04-05T22:04')
      end

      it "returns false" do
        expect(@sensor_data.valid?).to be false
      end
    end
  end
end

