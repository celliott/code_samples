module ApplicationHelper
  
  def display_error(field)
    if @user.errors[field].any?
        raw "<div class='errors'>"+@user.errors[field].first+"</div><br>"
    end
  end

end