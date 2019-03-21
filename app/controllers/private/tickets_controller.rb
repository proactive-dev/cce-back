module Private
  class TicketsController < BaseController
    layout false

    skip_before_action :verify_authenticity_token
    after_filter :mark_ticket_as_read, only: [:create, :show]

    def index
      @tickets = current_user.tickets
      render json: {
        total_length: @tickets.length,
        tickets: @tickets.page(params[:page]).per(params[:perPage])
      }
    end

    def new
      @ticket = Ticket.new
    end

    def create
      @ticket = current_user.tickets.create(ticket_params)
      if @ticket.save
        render json: @ticket
      else
        render json: {}
      end
    end

    def show
      @comments = ticket.comments
      @comments.unread_by(current_user).each do |c|
        c.mark_as_read! for: current_user
      end

      render json: {ticket: ticket, comments: @comments}
    end

    def destroy
      render_json(TicketSuccess.new(t('private.tickets.close_succ'))) if ticket.close!
    end

    private

    def ticket_params
      params.required(:ticket).permit(:title, :content)
    end

    def ticket
      @ticket ||= current_user.tickets.find(params[:id])
    end

    def mark_ticket_as_read
      ticket.mark_as_read!(for: current_user) if ticket.unread?(current_user)
    end
  end
end
