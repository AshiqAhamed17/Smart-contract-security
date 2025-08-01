// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {DeployLevelOne} from "../script/DeployLevelOne.s.sol";
import {GraduateToLevelTwo} from "../script/GraduateToLevelTwo.s.sol";
import {LevelOne} from "../src/LevelOne.sol";
import {LevelTwo} from "../src/LevelTwo.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";

contract LevelOneAndGraduateTest is Test {
    DeployLevelOne deployBot;
    GraduateToLevelTwo graduateBot;

    LevelOne levelOneProxy;
    LevelTwo levelTwoImplementation;

    address proxyAddress;
    address levelOneImplementationAddress;
    address levelTwoImplementationAddress;

    MockUSDC usdc;

    address principal;
    uint256 schoolFees;

    // teachers
    address alice;
    address bob;
    // students
    address clara;
    address dan;
    address eli;
    address fin;
    address grey;
    address harriet;

    function setUp() public {
        deployBot = new DeployLevelOne();
        proxyAddress = deployBot.deployLevelOne();
        levelOneProxy = LevelOne(proxyAddress);

        // graduateBot = new GraduateToLevelTwo();

        usdc = deployBot.getUSDC();
        principal = deployBot.principal();
        schoolFees = deployBot.getSchoolFees();
        levelOneImplementationAddress = deployBot.getImplementationAddress();

        alice = makeAddr("first_teacher");
        bob = makeAddr("second_teacher");

        clara = makeAddr("first_student");
        dan = makeAddr("second_student");
        eli = makeAddr("third_student");
        fin = makeAddr("fourth_student");
        grey = makeAddr("fifth_student");
        harriet = makeAddr("six_student");

        usdc.mint(clara, schoolFees);
        usdc.mint(dan, schoolFees);
        usdc.mint(eli, schoolFees);
        usdc.mint(fin, schoolFees);
        usdc.mint(grey, schoolFees);
        usdc.mint(harriet, schoolFees);
    }

    // My tests

    function test_reviewCountFlaw() public {
         // Step 1: Dan enrolls
        vm.startPrank(dan);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        assertEq(levelOneProxy.isStudent(dan), true);
        assertEq(levelOneProxy.studentScore(dan), 100);

        vm.prank(principal);
        levelOneProxy.addTeacher(alice);

        vm.warp(block.timestamp + 1 weeks);
        // Step 2: Alice gives Dan a bad review every week, more than 4 times
        for(uint i = 0; i<10; i++) {
            vm.warp(block.timestamp + 1 weeks);
            vm.prank(alice);
            levelOneProxy.giveReview(dan, false);
        }

        // Step 3: Final assertion - studentScore drops below graduation threshold
        assertEq(levelOneProxy.studentScore(dan), 0);
    }

        // levelTwoImplementation = new LevelTwo();
        // levelTwoImplementationAddress = address(levelTwoImplementation);

        // bytes memory data = abi.encodeCall(LevelTwo.graduate, ());

        // vm.prank(principal);
        // levelOneProxy.graduateAndUpgrade(levelTwoImplementationAddress, data);

        // LevelTwo levelTwoProxy = LevelTwo(proxyAddress);

        // console2.log(levelTwoProxy.bursary());
        // console2.log(levelTwoProxy.getTotalStudents());

    function test_wrongPayPerTeacher() view public {
        uint256 bursary = 1000; // Mocked bursary amount
        uint256 totalTeachers = 2;

        // Simulate current (broken) logic
        uint256 payPerTeacher = (bursary * levelOneProxy.TEACHER_WAGE()) / levelOneProxy.PRECISION();

        for (uint256 n = 0; n < totalTeachers; n++) {
            bursary = bursary - payPerTeacher;
        }
        console2.log("Bursary: ",bursary); // should be 650 but it's 300 due to wrong payPerTeacher calculation.

        // bursary should be 650 as only 35% of bursary is paid to teachers
        assertLe(bursary, 650); // Breaking of invariant - teachers share of 35% of bursary

    }

    function test_wrongPayPerTeacher2() view public {
    uint256 bursary = 1000; // Mocked bursary amount
    uint256 totalTeachers = 2;

    // Simulate current (broken) logic
    uint256 payPerTeacher = (bursary * levelOneProxy.TEACHER_WAGE()) / levelOneProxy.PRECISION();

    uint256 totalPaid = payPerTeacher * totalTeachers;

    console2.log("Bursary:", bursary); // 1000
    console2.log("Pay per teacher:", payPerTeacher); // 350
    console2.log("Total paid to teachers:", totalPaid); // 750

    // Invariant: Total teacher payment should be 35% of bursary (i.e., 350)
    uint256 expectedTotal = (bursary * levelOneProxy.TEACHER_WAGE()) / levelOneProxy.PRECISION();

    // Breaks invariant: actual > expected
    assertGt(totalPaid, expectedTotal); // 750 > 350
}





    // Ends My tests

    function test_confirm_first_deployment_is_level_one() public view {
        uint256 expectedTeacherWage = 35;
        uint256 expectedPrincipalWage = 5;
        uint256 expectedPrecision = 100;

        assertEq(levelOneProxy.TEACHER_WAGE(), expectedTeacherWage);
        assertEq(levelOneProxy.PRINCIPAL_WAGE(), expectedPrincipalWage);
        assertEq(levelOneProxy.PRECISION(), expectedPrecision);
        assertEq(levelOneProxy.getPrincipal(), principal);
        assertEq(levelOneProxy.getSchoolFeesCost(), deployBot.schoolFees());
        assertEq(levelOneProxy.getSchoolFeesToken(), address(usdc));
    }

    function test_confirm_add_teacher() public {
        vm.startPrank(principal);
        levelOneProxy.addTeacher(alice);
        levelOneProxy.addTeacher(bob);
        vm.stopPrank();

        assert(levelOneProxy.isTeacher(alice) == true);
        assert(levelOneProxy.isTeacher(bob) == true);
        assert(levelOneProxy.getTotalTeachers() == 2);
    }

    function test_confirm_cannot_add_teacher_if_not_principal() public {
        vm.expectRevert(LevelOne.HH__NotPrincipal.selector);
        levelOneProxy.addTeacher(alice);
    }

    function test_confirm_cannot_add_teacher_twice() public {
        vm.prank(principal);
        levelOneProxy.addTeacher(alice);

        vm.prank(principal);
        vm.expectRevert(LevelOne.HH__TeacherExists.selector);
        levelOneProxy.addTeacher(alice);
    }

    function test_confirm_remove_teacher() public {
        vm.startPrank(principal);
        levelOneProxy.addTeacher(alice);
        levelOneProxy.addTeacher(bob);
        vm.stopPrank();

        vm.prank(principal);
        levelOneProxy.removeTeacher(alice);

        assert(levelOneProxy.isTeacher(alice) == false);
        assert(levelOneProxy.getTotalTeachers() == 1);
    }

    function test_confirm_enroll() public {
        vm.startPrank(clara);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        assert(usdc.balanceOf(address(levelOneProxy)) == schoolFees);
    }

    function test_confirm_cannot_enroll_without_school_fees() public {
        address newStudent = makeAddr("no_school_fees");

        vm.prank(newStudent);
        vm.expectRevert();
        levelOneProxy.enroll();
    }

    function test_confirm_cannot_enroll_twice() public {
        vm.startPrank(eli);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        vm.prank(eli);
        vm.expectRevert(LevelOne.HH__StudentExists.selector);
        levelOneProxy.enroll();
    }

    modifier schoolInSession() {
        _teachersAdded();
        _studentsEnrolled();

        vm.prank(principal);
        levelOneProxy.startSession(70);

        _;
    }

    function test_confirm_can_give_review() public schoolInSession {
        vm.warp(block.timestamp + 1 weeks);

        vm.prank(alice);
        levelOneProxy.giveReview(harriet, false);

        assert(levelOneProxy.studentScore(harriet) == 90);
    }

    function test_confirm_can_graduate() public schoolInSession {
        levelTwoImplementation = new LevelTwo();
        levelTwoImplementationAddress = address(levelTwoImplementation);

        bytes memory data = abi.encodeCall(LevelTwo.graduate, ());

        vm.prank(principal);
        levelOneProxy.graduateAndUpgrade(levelTwoImplementationAddress, data);

        LevelTwo levelTwoProxy = LevelTwo(proxyAddress);

        console2.log(levelTwoProxy.bursary());
        console2.log(levelTwoProxy.getTotalStudents());
    }

    // ////////////////////////////////
    // /////                      /////
    // /////   HELPER FUNCTIONS   /////
    // /////                      /////
    // ////////////////////////////////

    function _teachersAdded() internal {
        vm.startPrank(principal);
        levelOneProxy.addTeacher(alice);
        levelOneProxy.addTeacher(bob);
        vm.stopPrank();
    }

    function _studentsEnrolled() internal {
        vm.startPrank(clara);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        vm.startPrank(dan);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        vm.startPrank(eli);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        vm.startPrank(fin);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        vm.startPrank(grey);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();

        vm.startPrank(harriet);
        usdc.approve(address(levelOneProxy), schoolFees);
        levelOneProxy.enroll();
        vm.stopPrank();
    }
}
