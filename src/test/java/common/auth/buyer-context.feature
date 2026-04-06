Feature: Buyer Context Helper
  Helper feature to provide buyer authentication context

  Scenario: Setup buyer headers
    * def buyerId = 'buyer-' + java.lang.System.currentTimeMillis()
