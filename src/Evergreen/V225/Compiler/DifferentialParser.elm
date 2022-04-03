module Evergreen.V225.Compiler.DifferentialParser exposing (..)

import Evergreen.V225.Compiler.AbstractDifferentialParser
import Evergreen.V225.Compiler.Acc
import Evergreen.V225.Parser.Block
import Evergreen.V225.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V225.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V225.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V225.Parser.Block.ExpressionBlock) Evergreen.V225.Compiler.Acc.Accumulator
