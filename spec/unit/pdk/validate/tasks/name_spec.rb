require 'spec_helper'

describe PDK::Validate::Tasks::Name do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  it 'defines the base validator attributes' do
    expect(described_class).to have_attributes(
      name: 'task-name',
    )
  end

  describe '.spinner_text' do
    subject(:spinner_text) { described_class.spinner_text(targets) }

    let(:targets) { [] }

    it { is_expected.to match(%r{checking task name}i) }
  end

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report) }

    let(:report) { PDK::Report.new }
    let(:glob_pattern) { File.join(module_root, described_class.pattern) }

    after(:each) do
      return_value
    end

    before(:each) do
      globbed_targets = targets.map { |r| File.join(module_root, r) }
      allow(Dir).to receive(:glob).with(glob_pattern, anything).and_return(globbed_targets)
      allow(File).to receive(:expand_path).with(module_root).and_return(module_root)
    end

    context 'when there are no targets' do
      let(:targets) { [] }

      it 'returns 0' do
        expect(return_value).to eq(0)
      end
    end

    context 'when a task name starts with a number' do
      let(:targets) { [File.join('tasks', '0_do_a_thing.sh')] }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   'task-name',
          state:    :failure,
          severity: 'error',
          message:  described_class::INVALID_TASK_MSG,
        )
      end

      it 'returns 1' do
        expect(return_value).to eq(1)
      end
    end

    context 'when a task name contains uppercase characters' do
      let(:targets) { [File.join('tasks', 'aTask.ps1')] }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   'task-name',
          state:    :failure,
          severity: 'error',
          message:  described_class::INVALID_TASK_MSG,
        )
      end

      it 'returns 1' do
        expect(return_value).to eq(1)
      end
    end

    context 'when the task name is valid' do
      let(:targets) { [File.join('tasks', 'a_task.rb')] }

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   'task-name',
          state:    :passed,
          severity: 'ok',
        )
      end

      it 'returns 0' do
        expect(return_value).to eq(0)
      end
    end
  end
end
