import java.io.File;
import org.gradle.tooling.BuildLauncher;
import org.gradle.tooling.GradleConnector;
import org.gradle.tooling.ProjectConnection;
import org.gradle.tooling.internal.consumer.DefaultGradleConnector;

public final class EmbeddedGradleBuild {
    public static void main(String[] args) {
        DefaultGradleConnector connector = (DefaultGradleConnector) GradleConnector.newConnector();
        connector.embedded(true);
        connector
            .useInstallation(new File(args[0]))
            .useGradleUserHomeDir(new File(args[2]))
            .forProjectDirectory(new File(args[1]));
        try (ProjectConnection connection = connector.connect()) {
            BuildLauncher build = connection.newBuild();
            build.forTasks(":app:assembleDebug");
            build.withArguments("--offline", "--init-script", args[3]);
            build.setStandardOutput(System.out);
            build.setStandardError(System.err);
            build.run();
        }
    }
}
