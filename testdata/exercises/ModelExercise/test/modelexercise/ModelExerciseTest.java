package modelexercise;

import fi.helsinki.cs.tmc.testrunner.Exercise;
import org.junit.Test;
import static org.junit.Assert.*;

public class ModelExerciseTest {
    @Test
    @Exercise("5.6")
    public void testReturnTrue()
    {
        assertTrue(ModelExercise.returnTrue());
    }
}
