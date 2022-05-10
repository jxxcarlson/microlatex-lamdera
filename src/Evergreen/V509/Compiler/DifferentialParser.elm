module Evergreen.V509.Compiler.DifferentialParser exposing (..)

import Evergreen.V509.Compiler.AbstractDifferentialParser
import Evergreen.V509.Compiler.Acc
import Evergreen.V509.Parser.Block
import Evergreen.V509.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V509.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V509.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V509.Parser.Block.ExpressionBlock) Evergreen.V509.Compiler.Acc.Accumulator
