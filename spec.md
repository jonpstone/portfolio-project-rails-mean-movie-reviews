# Specifications for the Rails Assessment

Specs:
- [x] Using Ruby on Rails for the project
**Used Rails 5.0**
- [x] Include at least one has_many relationship (x has_many y e.g. User has_many Recipes)
**A 'Writer' 'has_many' `Review`'s.**
- [x] Include at least one belongs_to relationship (x belongs_to y e.g. Post belongs_to User)
**A 'Review' 'belongs_to' a 'Writer'.**
- [x] Include at least one has_many through relationship (x has_many y through z e.g. Recipe has_many Items through Ingredients)
**A 'Review' 'has_many :genres, through: :review_genres'.**  
- [ ] The "through" part of the has_many through includes at least one user submittable attribute (attribute_name e.g. ingredients.quantity)
- [x] Include reasonable validations for simple model objects (list of model objects with validations e.g. User, Recipe, Ingredient, Item)
**Minimum length required for passwords content, etc., presence and uniqueness e.g. `usernames`'s and `review` `title`'s.**
- [x] Include a class level ActiveRecord scope method (model object & class method name and URL to see the working feature e.g. User.most_recipes URL: /users/most_recipes)
**I believe `Writer.latest_review` meets this expectation e.g. '/writers/1/reviews/1'**
- [x] Include a nested form writing to an associated model using a custom attribute writer (form URL, model name e.g. /recipe/new, Item)
**Upon creating a `Writer` the `User` must also create a `Review` on the same page, although the image attributes are added afterward '/writers/new'.**
- [x] Include signup (how e.g. Devise)
**Wrote a custom `User` model and controller.**
- [x] Include login (how e.g. Devise)
**Wrote a `SessionsController` with `create` action.**
- [x] Include logout (how e.g. Devise)
**Above also includes a `destroy` action**
- [x] Include third party signup/login (how e.g. Devise/OmniAuth)
**OmniAuth added to gemfile and logic integrated into `SessionsController` and `User` model**
- [x] Include nested resource show or index (URL e.g. users/2/recipes)
**/writers/1/reviews**
- [x] Include nested resource "new" form (URL e.g. recipes/1/ingredients)
**From the `Writer` show page, you can click 'Add a review' and be directed to new template e.g. '/writers/1/reviews/new'**
- [x] Include form display of validation errors (form URL e.g. /recipes/new)
**'/reviews/new'**

Confirm:
- [x] The application is pretty DRY
- [x] Limited logic in controllers
- [x] Views use helper methods if appropriate
- [x] Views use partials if appropriate
