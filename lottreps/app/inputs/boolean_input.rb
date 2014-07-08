class BooleanInput < SimpleForm::Inputs::BooleanInput
  def input
    if nested_boolean_style?
        template.label_tag(nil, :class => "checkbox") {
          build_check_box + inline_label
        }
    else
      build_check_box
    end
  end
end