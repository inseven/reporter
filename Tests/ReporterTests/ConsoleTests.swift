import Testing

@testable import ReporterCore

@Test("Check the shell correctly detects interactive mode")
func checkInteractiveShell() {
    #expect(Console().isInteractive == false)
}
