/**
 *
 * Scripts.js
 *
 * Initialization of the page scripts.
 *
 *
 */

class Scripts {
  constructor() {
    this._initCommon();
    this._initPages();
  }

  // Common plugins and overrides initialization
  _initCommon() {
    // common.js initialization
    if (typeof Common !== 'undefined') {
      let common = new Common();
    }
  }

  // Page scripts initialization
  _initPages() {
    // dashboard.elearning.js initialization
    if (typeof ElearningDashboard !== 'undefined') {
      const elearningDashboard = new ElearningDashboard();
    }

    // dashboard.school.js initialization
    if (typeof SchoolDashboard !== 'undefined') {
      const schoolDashboard = new SchoolDashboard();
    }

    // course.detail.js initialization
    if (typeof CourseDetail !== 'undefined') {
      const courseDetail = new CourseDetail();
    }

    // course.list.js initialization
    if (typeof CourseList !== 'undefined') {
      const courseList = new CourseList();
    }

    // course.explore.js initialization
    if (typeof CourseExplore !== 'undefined') {
      const courseExplore = new CourseExplore();
    }

    // instructor.list.js initialization
    if (typeof InstructorList !== 'undefined') {
      const instructorList = new InstructorList();
    }

    // instructor.detail.js initialization
    if (typeof InstructorDetail !== 'undefined') {
      const instructorDetail = new InstructorDetail();
    }

    // quiz.detail.js initialization
    if (typeof QuizDetail !== 'undefined') {
      const quizDetail = new QuizDetail();
    }

    // path.list.js initialization
    if (typeof PathList !== 'undefined') {
      const pathList = new PathList();
    }

    // path.detail.js initialization
    if (typeof PathDetail !== 'undefined') {
      const pathDetail = new PathDetail();
    }

    // misc.player.js initialization
    if (typeof MiscPlayer !== 'undefined') {
      const miscPlayer = new MiscPlayer();
    }
  }
}
