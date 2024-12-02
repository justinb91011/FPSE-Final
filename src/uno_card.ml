open Core

module UnoCard = struct
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

module UnoCardInstance = Card.Make(UnoCard)

module UnoCardUtils = struct
  include UnoCardInstance

  (* Function to convert a card to a string *)
  let to_string card =
    let color_to_string = function
      | UnoCard.Red -> "Red"
      | UnoCard.Yellow -> "Yellow"
      | UnoCard.Green -> "Green"
      | UnoCard.Blue -> "Blue"
      | UnoCard.WildColor -> "Wild"
    in
    let value_to_string = function
      | UnoCard.Number n -> string_of_int n
      | UnoCard.Skip -> "Skip"
      | UnoCard.Reverse -> "Reverse"
      | UnoCard.DrawTwo -> "DrawTwo"
      | UnoCard.DrawFour -> "DrawFour"
      | UnoCard.WildValue-> "Wild"
    in
    Printf.sprintf "%s %s" (color_to_string (get_color card)) (value_to_string (get_value card))
end