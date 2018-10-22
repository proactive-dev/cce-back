module Admin
  class Ability
    include CanCan::Ability

    def initialize(user)
      return unless user.admin?

      can :read, Order
      can :read, Trade
      can :read, Proof
      can :read, PaymentAddress
      can :manage, Document
      can :manage, Member
      can :manage, Affiliation
      can :manage, Ticket
      can :manage, IdDocument
      can :manage, TwoFactor

      can :menu, Deposit
      Deposit.descendants.each { |d| can :manage, d }

      can :menu, Withdraw
      Withdraw.descendants.each { |w| can :manage, w }

    end
  end
end
