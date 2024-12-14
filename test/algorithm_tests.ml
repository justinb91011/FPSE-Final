
open OUnit2
open Algorithm
open Uno_card
open Cpu


let test_rank_card_no_playable_card _ =
  let non_playable_top_card = UnoCardInstance.create UnoCard.Red (Number 5) in
  let cpu_card1 = UnoCardInstance.create UnoCard.Yellow (Number 8) in
  let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
  let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
  let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
  assert_equal 0 (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[3; 4] ~top_card:non_playable_top_card)

let test_rank_card_numbered_card _ =
  let top_card = UnoCardInstance.create UnoCard.Red (Number 8) in
  let cpu_card1 = UnoCardInstance.create UnoCard.Yellow (Number 8) in
  let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
  let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
  let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
  assert_equal 1 (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[3; 4] ~top_card)

  let test_rank_card_multiple_numbered_card _ =
    let top_card = UnoCardInstance.create UnoCard.Red (Number 8) in
    let cpu_card1 = UnoCardInstance.create UnoCard.Green (Number 8) in
    let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
    let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
    let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
    assert_equal 1 (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[3; 4] ~top_card)

  let test_rank_card_reverse_card_abs_1 _ =
    let top_card = UnoCardInstance.create UnoCard.Red (Number 6) in
    let cpu_card1 = UnoCardInstance.create UnoCard.Red (Reverse) in
    let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
    let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
    let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
    assert_equal (2) (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[3; 4] ~top_card)

  let test_rank_card_reverse_card_front_greater _ =
    let top_card = UnoCardInstance.create UnoCard.Red (Number 6) in
    let cpu_card1 = UnoCardInstance.create UnoCard.Red (Reverse) in
    let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
    let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
    let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
    assert_equal (1) (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[5; 3] ~top_card)

  let test_rank_card_reverse_card_back_greater _ =
    let top_card = UnoCardInstance.create UnoCard.Red (Number 6) in
    let cpu_card1 = UnoCardInstance.create UnoCard.Red (Reverse) in
    let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
    let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
    let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
    assert_equal (3) (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[2; 6] ~top_card)

    let test_rank_card_skip_card_base_case _ =
      (* Case where front <= 3 cards & next player > 3 cards. *)
      let top_card = UnoCardInstance.create UnoCard.Red (Number 6) in
      let cpu_card1 = UnoCardInstance.create UnoCard.Red (Skip) in
      let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
      let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
      let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
      assert_equal (4) (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[2; 6] ~top_card)

    let test_rank_card_skip_card_second_case _ =
      (* Case where secont front <= 3 cards & front > 3 cards. *)
      let top_card = UnoCardInstance.create UnoCard.Red (Number 6) in
      let cpu_card1 = UnoCardInstance.create UnoCard.Red (Skip) in
      let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
      let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
      let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
      assert_equal (2) (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[6; 3] ~top_card)
    
    let test_rank_card_skip_card_else_case _ =
      (* Case where secont front <= 3 cards & front > 3 cards. *)
      let top_card = UnoCardInstance.create UnoCard.Red (Number 6) in
      let cpu_card1 = UnoCardInstance.create UnoCard.Red (Skip) in
      let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
      let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
      let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
      assert_equal (3) (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[6; 6] ~top_card)
let series =
  "Algorithm Tests" >:::
  ["Algorithm Rank Card Test - Non Playable Card" >:: test_rank_card_no_playable_card;
   "Algorithm Rank Card Test - Numbered Card" >:: test_rank_card_numbered_card;
   "Algorithm Rank Card Test - Multiple Numbered Cards" >:: test_rank_card_multiple_numbered_card;
   "Algorithm Rank Card Test - Reverse Card ABS = 1" >:: test_rank_card_reverse_card_abs_1;
   "Algorithm Rank Card Test - Reverse Card front > back" >:: test_rank_card_reverse_card_front_greater;
   "Algorithm Rank Card Test - Reverse Card back > front" >:: test_rank_card_reverse_card_back_greater;
   "Algorithm Rank Card Test - Skip Card front <= 3 & next > 3" >:: test_rank_card_skip_card_base_case;
   "Algorithm Rank Card Test - Skip Card front >= 3 & next <= 3" >:: test_rank_card_skip_card_second_case;
   "Algorithm Rank Card Test - Skip Card front >= 3 & next > 3" >:: test_rank_card_skip_card_else_case;]