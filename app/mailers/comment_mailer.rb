class CommentMailer < BaseMailer

  def user_notification(comment_id)
    comment = Comment.find comment_id
    @ticket_url = "#{ENV['URL_SCHEMA']}://#{ENV['URL_UI']}/tickets/#{comment.ticket.id}"

    mail to: comment.ticket.author.email
  end

  def admin_notification(comment_id)
    comment = Comment.find comment_id
    @ticket_url = admin_ticket_url(comment.ticket)
    @author_email = comment.author.email

    mail to: ENV['SUPPORT_MAIL']
  end

end
