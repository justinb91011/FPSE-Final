open OUnit2
open Uno_card

let test_is_playable _ = 
  let card1 = UnoCardInstance.create Red (Number 5) in
  let card2 = UnoCardInstance.create Green (Number 4) in
  let card3 = UnoCardInstance.create WildColor (DrawFour) in
  let card4 = UnoCardInstance.create WildColor WildValue in
  let card5 = UnoCardInstance.create Red (Number 9) in
  let card6 = UnoCardInstance.create Blue (Number 4) in
  assert_bool "card1 is not playable with card2." (not (UnoCard.is_playable (UnoCardInstance.get_color card1) (UnoCardInstance.get_value card1)
  (UnoCardInstance.get_color card2) (UnoCardInstance.get_value card2)));
  assert_bool "card3 is playable with card2." (UnoCard.is_playable (UnoCardInstance.get_color card3) (UnoCardInstance.get_value card3)
  (UnoCardInstance.get_color card2) (UnoCardInstance.get_value card2));
  assert_bool "card4 is playable with card1." (UnoCard.is_playable (UnoCardInstance.get_color card4) (UnoCardInstance.get_value card4)
  (UnoCardInstance.get_color card1) (UnoCardInstance.get_value card1));
  assert_bool "card5 is playable with card1." (UnoCard.is_playable (UnoCardInstance.get_color card5) (UnoCardInstance.get_value card5)
  (UnoCardInstance.get_color card1) (UnoCardInstance.get_value card1));
  assert_bool "card6 is playable with card2." (UnoCard.is_playable (UnoCardInstance.get_color card6) (UnoCardInstance.get_value card6)
  (UnoCardInstance.get_color card2) (UnoCardInstance.get_value card2))

  let series =
    "Uno_card Tests" >:::
    ["Uno Card Playability" >:: test_is_playable]