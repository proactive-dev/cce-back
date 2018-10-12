module LoanMatching
  class LoanGroup

    attr :loans

    def initialize()
      @loans = []
    end

    def top
      @loans.first
    end

    def empty?
      @loans.empty?
    end

    def add(loan)
      @loans << loan
    end

    def update(loan)
      loan.auto_renew = !loan.auto_renew
      @loans.map { |l| l.id == loan.id ? loan : l }
    end

    def remove(loan)
      @loans.delete_if {|o| o.id == loan.id }
    end

    def find(id)
      @loans.find {|o| o.id == id }
    end

  end
end
