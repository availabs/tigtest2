class AdminMailer < ActionMailer::Base
  default from: (ENV["SYSTEM_SEND_FROM_ADDRESS"] || "nymtc_gateway@tig.nymtc.org")

  def new_contribution_email(user, obj)
    @user = (user == User.default) ? nil : user
    @obj = obj
    mail(to: @user.email, subject: "A new #{@obj.class.to_s} has been contributed to the Gateway") if @user && @obj
  end
end
