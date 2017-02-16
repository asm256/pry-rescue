require File.expand_path('../../lib/pry-rescue.rb', __FILE__)

describe 'Pry.rescue' do
  it 'should call PryRescue.enter_exception_context' do
    expect{
      expect(PryRescue).to receive(:enter_exception_context).once
      Pry::rescue{ raise "foobar" }
    }.to raise_error(/foobar/)
  end

  it "should retry on try-again" do
    @called = 0
    expect(PryRescue).to receive(:enter_exception_context).once{ throw :try_again }
    Pry::rescue do
      @called += 1
      raise "foobar" if @called == 1
    end
    expect(@called).to eq(2)
  end

  it "should try-again from innermost block" do
    @outer = @inner = 0
    expect(PryRescue).to receive(:enter_exception_context).once{ throw :try_again }
    Pry::rescue do
      @outer += 1
      Pry::rescue do
        @inner += 1
        raise "oops" if @inner == 1
      end
    end

    expect(@outer).to eq(1)
    expect(@inner).to eq(2)
  end

  it "should enter the first occurence of an exception that is re-raised" do
    expect(PryRescue).to receive(:enter_exception_context).once{ |raised| expect(raised.size).to eq(1) }
    expect do
      Pry::rescue do
        begin
          raise "first_occurance"
        rescue => e
          raise
        end
      end
    end.to raise_error(/first_occurance/)
  end

  it "should not catch SystemExit" do
    expect(PryRescue).not_to receive(:enter_exception_context)

    expect do
      Pry::rescue do
        exit
      end
    end.to raise_error SystemExit
  end

  it 'should not catch Ctrl+C' do
    expect(PryRescue).not_to receive(:enter_exception_context)
    expect do
      Pry::rescue do
        raise Interrupt, "ctrl+c (fake)"
      end
    end.to raise_error Interrupt
  end
end

describe "Pry.rescued" do

  it "should raise an error if used outwith Pry::rescue" do
    begin
      raise "foo"
    rescue => e
      expect(Pry).to receive(:warn)
      Pry.rescued(e)
    end
  end

  it "should raise an error if used on an exception not raised" do
    Pry::rescue do
      expect(Pry).to receive(:warn) do |message|
        expect(message).to match(/^WARNING: Tried to inspect exception outside of Pry::rescue/)
      end
      Pry.rescued(RuntimeError.new("foo").exception)
    end
  end

  it "should call Pry.enter_exception_context" do
    Pry::rescue do
      begin
        raise "foo"
      rescue => e
        expect(PryRescue).to receive(:enter_exception_context).once
        Pry::rescued(e)
      end
    end
  end
end

