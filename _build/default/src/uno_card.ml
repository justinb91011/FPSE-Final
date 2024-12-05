open Core

module UnoCard = struct
  type color = Red | Yellow | Green | Blue | WildColor [@@deriving compare, equal, sexp] [@@coverage off]

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


