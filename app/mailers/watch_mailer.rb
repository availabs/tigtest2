class WatchMailer < ActionMailer::Base
  default from: (ENV["SYSTEM_SEND_FROM_ADDRESS"] || "nymtc_gateway@tig.nymtc.org")

  def metadata_email(user, obj)
    @user = (user == User.default) ? nil : user
    @obj = obj
    mail(to: @user.email, subject: "Metadata for '#{@obj.name}' has been changed") if @user && @obj
  end

  def comment_email(user, obj, comment)
    @user = (user == User.default) ? nil : user
    @obj = obj
    @comment = comment
    mail(to: @user.email, subject: "New comment on '#{@obj.name}'") if @user && @obj
  end
end
