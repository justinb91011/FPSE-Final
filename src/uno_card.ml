module UnoCard = struct
  type color = Red | Yellow | Green | Blue | Wild [@@deriving compare]

  type value = Number of int | Skip | Reverse | DrawTwo | DrawFour | Wild
  
  let is_playable (color1 : color) (value1 : value) (color2 : color) (value2 : value)=
    match (color1, value1), (color2, value2) with
    | (_, Wild), _ -> true
    | (Wild, _), _ -> true
    | (c1, _), (c2, _) when c1 = c2 -> true
    | (_, v1), (_, v2) when v1 = v2 -> true
    | _ -> false
end

module UnoCardMade = Card.Make(UnoCard)