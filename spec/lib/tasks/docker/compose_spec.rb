require 'spec_helper'

def fetch(arg)
  options.fetch(arg)
end

describe "compose.rake" do
  describe "_compose_option_project_name" do
    subject { _compose_option_project_name }
    let(:options) { { docker_compose_project_name: "test" } }

    it "returns proper option" do
      expect(subject).to eq "-p test"
    end
  end

  describe "_compose_option_compose_path" do
    subject { _compose_option_compose_path }

    describe "empty docker_compose_path option" do
      let(:options) { { docker_compose_path: nil } }

      it "returns empty string" do
        expect(subject).to eq ""
      end
    end

    describe "single value given" do
      let(:options) { { docker_compose_path: "compose.yml"} }

      it "returns proper option" do
        expect(subject).to eq "-f compose.yml"
      end
    end

    describe "array given" do
      let(:options) { { docker_compose_path: ["docker.yml", "compose.yml"] } }

      it "returns proper options" do
        expect(subject).to eq "-f docker.yml -f compose.yml"
      end
    end
  end

  describe "_compose_option_build_services" do
    subject { _compose_option_build_services }

    describe "empty docker_compose_build_services given" do
      let(:options) { { docker_compose_build_services: nil } }
      it "returns empty string" do
        expect(subject).to eq ""
      end
    end

    describe "single service given" do
      let(:options) { { docker_compose_build_services: "test" } }
      it "returns proper option" do
        expect(subject).to eq "test"
      end
    end

    describe "multiple services given" do
      let(:options) { { docker_compose_build_services: "foo bar" } }
      it "returns proper option" do
        expect(subject).to eq "foo bar"
      end
    end
  end

  describe "commands" do
    let(:_compose_option_project_name) { "-p project" }
    let(:_compose_option_compose_path) { "-f compose.yml" }
    let(:_compose_option_build_services) { "foo" }

    describe "compose_start_command" do
      subject { compose_start_command }

      it "returns command with proper options order" do
        expect(subject).to eq "-f compose.yml -p project up -d foo"
      end
    end

    describe "compose_build_command" do
      subject { compose_build_command }

      it "returns command with proper options order" do
        expect(subject).to eq "-f compose.yml -p project build foo"
      end
    end

    describe "compose_stop_command" do
      subject { compose_stop_command }

      it "returns command with proper options order" do
        expect(subject).to eq "-f compose.yml -p project stop"
      end
    end

    describe "compose_remove_command" do
      subject { compose_remove_command }

      describe "with removing volumes" do
        let(:options) { { docker_compose_remove_volumes: true } }

        it "returns command with proper options order" do
          expect(subject).to eq "-f compose.yml -p project rm -f -v"
        end
      end

      describe "without removing volumes" do
        let(:options) { { docker_compose_remove_volumes: nil } }
        it "returns command with proper options order" do
          expect(subject).to eq "-f compose.yml -p project rm -f"
        end
      end
    end

    describe "compose_down_command" do
      subject { compose_down_command }

      it "returns command with proper options order" do
        expect(subject).to eq "-f compose.yml -p project down"
      end
    end

    describe "compose_run_command" do
      let(:service) { "app" }
      let(:cmd) { "rake" }

      subject { compose_run_command(service, cmd) }

      it "returns command with proper options order" do
        expect(subject).to eq "-f compose.yml -p project run app rake"
      end
    end
  end
end
