module Evergreen.V722.Compiler.DifferentialParser exposing (..)

import Evergreen.V722.Compiler.AbstractDifferentialParser
import Evergreen.V722.Compiler.Acc
import Evergreen.V722.Parser.Block
import Evergreen.V722.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V722.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V722.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V722.Parser.Block.ExpressionBlock) Evergreen.V722.Compiler.Acc.Accumulator
