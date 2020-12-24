require 'spec_helper'

describe Attachment do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:document) }
end
