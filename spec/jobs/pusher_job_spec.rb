require 'spec_helper'

RSpec.describe PusherJob do
  describe '#perform' do
    let!(:channel)  { 'channel' }
    let!(:message)  { 'message' }
    let!(:payload)  { 'payload' }
    let!(:pusher)   { instance_double 'Pusher::Channel' }

    before do
      allow(Pusher).to receive(:[]).with(channel).and_return(pusher)
      allow(pusher).to receive(:trigger).and_return(true)
    end

    it 'should call Pusher with the message and payload on the given channel' do
      PusherJob.new.perform(channel, message, payload)
      expect(pusher).to have_received(:trigger).with(message, message: payload)
    end
  end
end
