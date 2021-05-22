{-# LANGUAGE ScopedTypeVariables #-}

-- [The Weekly Challenge - 113](https://perlweeklychallenge.org/blog/perl-weekly-challenge-113/),
-- TASK #1: Represent Integer

-- You are given a positive integer `n` and a digit `d`.

-- Write a script to check if `n` can be represented as a sum of
-- positive integers [all] having `d` at least once [in their decimal
-- representation]. If check passes print 1 otherwise 0.

module RepresentInteger where
import qualified Data.Set as Set
import Data.Maybe
import Data.Either

-- I'm using parens instead of $ and `let` instead of `where` to make
-- the code look closer to the Perl version / more familiar to Perl
-- programmers.

-- Also, using this now pretty wide-spread (but not sure about
-- Haskell) piping operator to make the code look similar to OO code
-- using method calls.
(|>) a b = b a

chooseOptim2 :: forall n. (Num n, Ord n) => n -> [n] -> Maybe [n]
chooseOptim2 n ns =
  let nsSet = Set.fromList ns
      check :: [n] -> Maybe [n]
      check chosen =
        let decide n =
              let chosen' = n:chosen
                  total = sum chosen'
                  missing = n - total
              in
                if missing == 0 then
                  Just (Right chosen')
                else if missing < 0 then
                  Nothing
                else
                  if Set.member missing nsSet then
                    Just (Right (missing : chosen'))
                  else
                    Just (Left (check chosen'))
            decisions :: [Either (Maybe [n]) [n]]
            decisions = ns |> map decide |> takeWhile isJust |> catMaybes
            solutions :: [[n]]
            solutions = rights decisions
            recursions :: [Maybe [n]]
            recursions = lefts decisions
        in
          case solutions of
            (solution:_) -> Just solution
            _ ->
              case recursions |> catMaybes of
                (solution:_) -> Just solution
                _ -> Nothing
  in
    check []

representableNumbers :: Integer -> Char -> [ Integer ]
representableNumbers n d =
  filter (\i -> elem d (show i)) [1..n]

representable :: Integer -> Char -> Maybe [Integer]
representable n d =
  let ns = representableNumbers n d
  in
    chooseOptim2 n (reverse ns)

