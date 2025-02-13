import Testing

import ReporterCore

@Test("Check the shell correctly detects interactive mode")
func checkInteractiveShell() {
    #expect(Shell.isInteractive == false)
}
