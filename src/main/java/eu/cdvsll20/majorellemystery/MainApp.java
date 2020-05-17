package eu.cdvsll20.majorellemystery;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

import java.io.IOException;
import java.net.URL;

public class MainApp extends Application {

    @Override
    public void start(Stage stage) {
        stage.setTitle("Escape Villa - the Majorelle Mystery");

        try {
            // TODO: need to fix loading issue
            URL location = MainApp.class.getResource("house.fxml");
            if (location != null) {
                Group root = FXMLLoader.load(location);
                Scene scene = new Scene(root);
                stage.setScene(scene);
                stage.show();
            } else {
                String javaVersion = System.getProperty("java.version");
                String javafxVersion = System.getProperty("javafx.version");
                Label l = new Label("Hello, JavaFX " + javafxVersion + ", running on Java " + javaVersion + ".");
                Scene scene = new Scene(new StackPane(l), 640, 480);
                stage.setScene(scene);
                stage.show();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        launch();
    }
}
