require "spec_helper"

describe "answer location data" do
  let(:form) { create(:form, question_types: question_types) }
  let(:questioning) { form.questionings.first }

  describe ".location_answers_for_mission" do
    let(:question_types) { %w(location select_one select_multiple text integer) }
    before do
      # Configure select one question to be geographic
      select_one_questioning = form.questionings.second
      select_one_option = select_one_questioning.options.first
      select_one_questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
      select_one_option.update_attributes(latitude: 0, longitude: 0)

      # Configure select multiple question to be geographic
      select_multiple_questioning = form.questionings.third
      option_one = select_multiple_questioning.options.first
      option_two = select_multiple_questioning.options.second
      select_multiple_questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
      option_one.update_attributes(latitude: 0, longitude: 0)
      option_two.update_attributes(latitude: 0, longitude: 0)

      form.publish!

      create(:response, form: form,
        answer_values: ["12.34 -56.78", [select_one_option.name],
        [option_one.name, option_two.name], "Non geo answer", 12])
    end

    it "returns all answers for locations on a certain mission" do
      location_answers = Answer.location_answers_for_mission(get_mission)
      expect(location_answers.length).to eq 4
    end
  end



  describe "#location_type_with_value?" do
    context "with questioning of location type" do
      let(:question_types) { %w(location) }

      it "returns true" do
        answer = create(:answer, questioning: questioning, value: "12.34 -56.78")
        expect(answer.location_type_with_value?).to be true
      end
    end

    context "with questioning of a different type" do
      let(:question_types) { %w(text) }

      it "returns false" do
        answer = create(:answer, questioning: questioning, value: "12.34 -56.78")
        expect(answer.location_type_with_value?).to be false
      end
    end
  end

  describe "#has_coordinates?" do
    context "with a select_one question" do
      let(:question_types) { %w(select_one) }
      let(:option) { questioning.options.first }

      it "should return false if the selected option does not have coordinates" do
        answer = create(:answer, option: option, questioning: questioning)
        expect(answer).not_to have_coordinates
      end

      it "should return true if the selected option has coordinates" do
        questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        option.update_attributes(latitude: 0, longitude: 0)

        answer = create(:answer, option: option, questioning: questioning)
        expect(answer).to have_coordinates
      end
    end

    context "with a select_multiple question" do
      let(:question_types) { %w(select_multiple) }
      let(:option_one) { questioning.options.first }
      let(:option_two) { questioning.options.second }
      let(:answer) { create(:answer, questioning: questioning, choices: choices) }

      context "with no choices" do
        let(:choices) { [] }

        it "should return false if no options were selected" do
          answer = create(:answer, questioning: questioning)
          expect(answer).not_to have_coordinates
        end
      end

      context "with choices" do
        let(:choices) { [build(:choice, option: option_one), build(:choice, option: option_two)] }

        before do
          questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        end

        it "should return false if the selected options do not have coordinates" do
          expect(answer).not_to have_coordinates
        end

        it "should return true if all of the selected options have coordinates" do
          option_one.update_attributes(latitude: 0, longitude: 0)
          option_two.update_attributes(latitude: 0, longitude: 0)
          expect(answer).to have_coordinates
        end

        it "should return true if any of the selected options have coordinates" do
          option_one.update_attributes(latitude: 0, longitude: 0)
          expect(answer).to have_coordinates
        end
      end
    end

    context "with a location question" do
      let(:question_types) { %w(location) }

      it "should return true if answer given" do
        answer = create(:answer, questioning: questioning, value: "12.3 45.6")
        expect(answer).to have_coordinates
      end

      it "should return false if answer blank" do
        answer = create(:answer, questioning: questioning, value: "")
        expect(answer).not_to have_coordinates
      end
    end
  end

  describe "#replicate_location_values" do
    context "when the answer is for simple location type question" do
      let(:question_types) { %w(location) }

      it "copies the coordinates from value to the lat/long fields" do
        answer = create(:answer, questioning: questioning, value: "12.34 -56.78")

        expect(answer.simple_location_answer?).to be true
        expect(answer.latitude).to eq 12.34
        expect(answer.longitude).to eq -56.78
      end
    end

    context "when answer is for a select one question of a location" do
      let(:question_types) { %w(select_one) }
      let(:questioning) { form.questionings.first }
      let(:option) { questioning.options.first }

      it "copies the coordinates from the option to the answer lat/long columns" do
        questioning.option_set.update_attributes(geographic: true, allow_coordinates: true)
        option.update_attributes(latitude: 12.34, longitude: -56.78)

        answer = create(:answer, option: option, questioning: questioning)
        expect(answer.latitude).to eq 12.34
        expect(answer.longitude).to eq -56.78
      end
    end
  end
end
