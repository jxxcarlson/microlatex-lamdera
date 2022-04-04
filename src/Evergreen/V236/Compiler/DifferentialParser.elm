module Evergreen.V236.Compiler.DifferentialParser exposing (..)

import Evergreen.V236.Compiler.AbstractDifferentialParser
import Evergreen.V236.Compiler.Acc
import Evergreen.V236.Parser.Block
import Evergreen.V236.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V236.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V236.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V236.Parser.Block.ExpressionBlock) Evergreen.V236.Compiler.Acc.Accumulator
