open Core
open OUnit2
open Card

module TestCard = struct
  type color = Red | Yellow | Green | Blue | WildColor [@@deriving compare, equal, sexp]
  type value = Number of int | Skip | Reverse | DrawTwo | DrawFour | WildValue [@@deriving compare, equal, sexp]

  let is_playable (color1 : color) (value1 : value) (color2 : color) (value2 : value) =
    match (color1, value1), (color2, value2) with
    | (_, WildValue), _ -> true
    | (WildColor, _), _ -> true
    | (c1, _), (c2, _) when equal_color c1 c2 -> true
    | (_, v1), (_, v2) when equal_value v1 v2 -> true
    | _ -> false
end

module Card = Make(TestCard)

let card1 = Card.create TestCard.Red (TestCard.Number 5)
let card2 = Card.create TestCard.Blue (TestCard.Reverse)
let card3 = Card.create TestCard.Green (TestCard.DrawTwo)
let card4 = Card.create TestCard.Yellow (TestCard.Skip)
let card5 = Card.create TestCard.WildColor (TestCard.DrawFour)

let test_card_sexp _ = 
  assert_equal "Red (Number 5)" ((Sexp.to_string(TestCard.sexp_of_color (Card.get_color card1)))^
                                " "^(Sexp.to_string(TestCard.sexp_of_value (Card.get_value card1))));
  assert_equal "Blue Reverse" ((Sexp.to_string(TestCard.sexp_of_color (Card.get_color card2)))^
  " "^(Sexp.to_string(TestCard.sexp_of_value (Card.get_value card2))));
  assert_equal "Green DrawTwo" ((Sexp.to_string(TestCard.sexp_of_color (Card.get_color card3)))^
  " "^(Sexp.to_string(TestCard.sexp_of_value (Card.get_value card3))));
  assert_equal "Yellow Skip" ((Sexp.to_string(TestCard.sexp_of_color (Card.get_color card4)))^
  " "^(Sexp.to_string(TestCard.sexp_of_value (Card.get_value card4))));
  assert_equal "WildColor DrawFour" ((Sexp.to_string(TestCard.sexp_of_color (Card.get_color card5)))^
  " "^(Sexp.to_string(TestCard.sexp_of_value (Card.get_value card5))))
let test_is_playable _ =
  assert_bool "card1 : Red (Number 5) is not playable with card2 : Blue Reverse." (not (TestCard.is_playable (Card.get_color card1) (Card.get_value card1)
                                          (Card.get_color card2) (Card.get_value card2)));
  assert_bool "card5 : WildColor DrawFour is playable on card3 : Blue Reverse."
    (TestCard.is_playable (Card.get_color card5) (Card.get_value card5)
                          (Card.get_color card3) (Card.get_value card3))



let series = 
  "Card Tests" >:::
  [ "Card Sexp Conversion" >:: test_card_sexp; 
    "Card Playability" >:: test_is_playable]

