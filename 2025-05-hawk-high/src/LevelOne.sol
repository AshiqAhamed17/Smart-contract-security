// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* 
 __    __                       __            __    __ __          __       
|  \  |  \                     |  \          |  \  |  \  \        |  \      
| ▓▓  | ▓▓ ______  __   __   __| ▓▓   __     | ▓▓  | ▓▓\▓▓ ______ | ▓▓____  
| ▓▓__| ▓▓|      \|  \ |  \ |  \ ▓▓  /  \    | ▓▓__| ▓▓  \/      \| ▓▓    \ 
| ▓▓    ▓▓ \▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓ ▓▓_/  ▓▓    | ▓▓    ▓▓ ▓▓  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓/      ▓▓ ▓▓ | ▓▓ | ▓▓ ▓▓   ▓▓     | ▓▓▓▓▓▓▓▓ ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓  ▓▓▓▓▓▓▓ ▓▓_/ ▓▓_/ ▓▓ ▓▓▓▓▓▓\     | ▓▓  | ▓▓ ▓▓ ▓▓__| ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓\▓▓    ▓▓\▓▓   ▓▓   ▓▓ ▓▓  \▓▓\    | ▓▓  | ▓▓ ▓▓\▓▓    ▓▓ ▓▓  | ▓▓
 \▓▓   \▓▓ \▓▓▓▓▓▓▓ \▓▓▓▓▓\▓▓▓▓ \▓▓   \▓▓     \▓▓   \▓▓\▓▓_\▓▓▓▓▓▓▓\▓▓   \▓▓
                                                         |  \__| ▓▓         
                                                          \▓▓    ▓▓         
                                                           \▓▓▓▓▓▓          

*/

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Hawk High First Flight
 * @author Chukwubuike Victory Chime @yeahChibyke
 * @notice Contract for the Hawk High School
 */
contract LevelOne is Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    ////////////////////////////////
    /////                      /////
    /////      VARIABLES       /////
    /////                      /////
    ////////////////////////////////
    address principal;
    bool inSession;
    uint256 schoolFees;
    uint256 public immutable reviewTime = 1 weeks;
    uint256 public sessionEnd;
    uint256 public bursary;
    uint256 public cutOffScore;
    mapping(address => bool) public isTeacher;
    mapping(address => bool) public isStudent;
    mapping(address => uint256) public studentScore;
    mapping(address => uint256) private reviewCount;
    mapping(address => uint256) private lastReviewTime;
    address[] listOfStudents;
    address[] listOfTeachers;

    uint256 public constant TEACHER_WAGE = 35; // 35%
    uint256 public constant PRINCIPAL_WAGE = 5; // 5%
    uint256 public constant PRECISION = 100;

    IERC20 usdc;

    ////////////////////////////////
    /////                      /////
    /////        EVENTS        /////
    /////                      /////
    ////////////////////////////////
    event TeacherAdded(address indexed);
    event TeacherRemoved(address indexed);
    event Enrolled(address indexed);
    event Expelled(address indexed);
    event SchoolInSession(uint256 indexed startTime, uint256 indexed endTime);
    event ReviewGiven(address indexed student, bool indexed review, uint256 indexed studentScore);
    //@audit-ok - low Graduate event not emitted anywhere in the contract
    event Graduated(address indexed levelTwo);

    ////////////////////////////////
    /////                      /////
    /////        ERRORS        /////
    /////                      /////
    ////////////////////////////////
    error HH__NotPrincipal();
    error HH__NotTeacher();
    error HH__ZeroAddress();
    error HH__TeacherExists();
    error HH__StudentExists();
    error HH__TeacherDoesNotExist();
    error HH__StudentDoesNotExist();
    error HH__AlreadyInSession();
    error HH__ZeroValue();
    error HH__HawkHighFeesNotPaid();
    error HH__NotAllowed();

    ////////////////////////////////
    /////                      /////
    /////      MODIFIERS       /////
    /////                      /////
    ////////////////////////////////
    modifier onlyPrincipal() {
        if (msg.sender != principal) {
            revert HH__NotPrincipal();
        }
        _;
    }

    modifier onlyTeacher() {
        if (!isTeacher[msg.sender]) {
            revert HH__NotTeacher();
        }
        _;
    }

    modifier notYetInSession() {
        if (inSession == true) {
            revert HH__AlreadyInSession();
        }
        _;
    }

    ////////////////////////////////
    /////                      /////
    /////     INITIALIZER      /////
    /////                      /////
    ////////////////////////////////
    /// Constructor for logic contracts
    /// sets up storage in the proxy during deployment.
    //@audit-ok can this have two owners ? - No becoz of initializer modifier
    //? Storage collisions ?
    function initialize(address _principal, uint256 _schoolFees, address _usdcAddress) public initializer {
        if (_principal == address(0)) {
            revert HH__ZeroAddress();
        }
        if (_schoolFees == 0) {
            revert HH__ZeroValue();
        }
        //? What is the usdcAddress is a weird ERC20 address rather than usdcAddress ?
        if (_usdcAddress == address(0)) {
            revert HH__ZeroAddress();
        }

        principal = _principal;
        schoolFees = _schoolFees;
        usdc = IERC20(_usdcAddress);

        __UUPSUpgradeable_init();
    }

    ////////////////////////////////
    /////                      /////
    /////  EXTERNAL FUNCTIONS  /////
    /////                      /////
    ////////////////////////////////
    
    /// Enrolls only students, has to pay the school fees
    function enroll() external notYetInSession {
        if (isTeacher[msg.sender] || msg.sender == principal) {
            revert HH__NotAllowed();
        }
        if (isStudent[msg.sender]) {
            revert HH__StudentExists();
        }
        usdc.safeTransferFrom(msg.sender, address(this), schoolFees);

        listOfStudents.push(msg.sender);
        isStudent[msg.sender] = true;
        studentScore[msg.sender] = 100;
        bursary += schoolFees;

        emit Enrolled(msg.sender);
    }

    function getPrincipal() external view returns (address) {
        return principal;
    }

    function getSchoolFeesCost() external view returns (uint256) {
        return schoolFees;
    }

    function getSchoolFeesToken() external view returns (address) {
        return address(usdc);
    }

    function getTotalTeachers() external view returns (uint256) {
        return listOfTeachers.length;
    }

    function getTotalStudents() external view returns (uint256) {
        return listOfStudents.length;
    }

    function getListOfStudents() external view returns (address[] memory) {
        return listOfStudents;
    }

    function getListOfTeachers() external view returns (address[] memory) {
        return listOfTeachers;
    }

    function getSessionStatus() external view returns (bool) {
        return inSession;
    }

    function getSessionEnd() external view returns (uint256) {
        return sessionEnd;
    }

    ////////////////////////////////
    /////                      /////
    /////   PUBLIC FUNCTIONS   /////
    /////                      /////
    ////////////////////////////////
    function addTeacher(address _teacher) public onlyPrincipal notYetInSession {
        if (_teacher == address(0)) {
            revert HH__ZeroAddress();
        }

        if (isTeacher[_teacher]) {
            revert HH__TeacherExists();
        }

        if (isStudent[_teacher]) {
            revert HH__NotAllowed();
        }

        listOfTeachers.push(_teacher);
        isTeacher[_teacher] = true;

        emit TeacherAdded(_teacher);
    }

    function removeTeacher(address _teacher) public onlyPrincipal {
        if (_teacher == address(0)) {
            revert HH__ZeroAddress();
        }

        if (!isTeacher[_teacher]) {
            revert HH__TeacherDoesNotExist();
        }

        // ? possible DOS ? ,
        uint256 teacherLength = listOfTeachers.length;
        for (uint256 n = 0; n < teacherLength; n++) {
            if (listOfTeachers[n] == _teacher) {
                listOfTeachers[n] = listOfTeachers[teacherLength - 1];
                listOfTeachers.pop();
                break;
            }
        }

        isTeacher[_teacher] = false;

        emit TeacherRemoved(_teacher);
    }

    function expel(address _student) public onlyPrincipal {
        if (inSession == false) {
            revert();
        }
        if (_student == address(0)) {
            revert HH__ZeroAddress();
        }

        if (!isStudent[_student]) {
            revert HH__StudentDoesNotExist();
        }

        // ? Possible DOS ?
        uint256 studentLength = listOfStudents.length;
        for (uint256 n = 0; n < studentLength; n++) {
            if (listOfStudents[n] == _student) {
                listOfStudents[n] = listOfStudents[studentLength - 1];
                listOfStudents.pop();
                break;
            }
        }

        isStudent[_student] = false;

        emit Expelled(_student);
    }

    function startSession(uint256 _cutOffScore) public onlyPrincipal notYetInSession {
        sessionEnd = block.timestamp + 4 weeks;
        inSession = true;
        cutOffScore = _cutOffScore;

        emit SchoolInSession(block.timestamp, sessionEnd);
    }

    function giveReview(address _student, bool review) public onlyTeacher {
        if (!isStudent[_student]) {
            revert HH__StudentDoesNotExist();
        }

        //@audit-ok - high reviewCount is never updated, so its always < 5.
        require(reviewCount[_student] < 5, "Student review count exceeded!!!");
        require(block.timestamp >= lastReviewTime[_student] + reviewTime, "Reviews can only be given once per week");

        // where `false` is a bad review and true is a good review
        if (!review) {
            studentScore[_student] -= 10;
        }

        // Update last review time
        lastReviewTime[_student] = block.timestamp;

        emit ReviewGiven(_student, review, studentScore[_student]);
    }

    /// Performs UUPS upgrade
    function graduateAndUpgrade(address _levelTwo, bytes memory) public onlyPrincipal {
        if (_levelTwo == address(0)) {
            revert HH__ZeroAddress();
        }

        uint256 totalTeachers = listOfTeachers.length;

        //@audit-ok - high wrong calculation for payPerTeacher
        uint256 payPerTeacher = (bursary * TEACHER_WAGE) / PRECISION;
        uint256 principalPay = (bursary * PRINCIPAL_WAGE) / PRECISION;

        _authorizeUpgrade(_levelTwo);

        for (uint256 n = 0; n < totalTeachers; n++) {
            usdc.safeTransfer(listOfTeachers[n], payPerTeacher);
        }

        usdc.safeTransfer(principal, principalPay);

        //@audit-ok - low needs a event to emit -  emit Graduated(_leveltwo);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyPrincipal {}
}
