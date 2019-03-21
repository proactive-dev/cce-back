module Private
  class CommentsController < BaseController
    layout false

    def create
      comment = ticket.comments.new(comment_params.merge(author_id: current_user.id))

      if comment.save
        render_json(TicketSuccess.new(t('private.tickets.comment_succ')))
      else
        render_json(TicketFailure.new(t('private.tickets.comment_fail')))
      end
    end

    private

    def comment_params
      params.required(:comment).permit(:content)
    end

    def ticket
      @ticket ||= current_user.tickets.find(params[:ticket_id])
    end

  end
end
