package pkg;

import fi.helsinki.cs.tmc.edutestutils.Points;
import org.junit.Test;
import static org.junit.Assert.*;

@Points("packagedtest")
public class PackagedTest {
    @Test
    public void testPackagedMethod() throws Exception {
        assertEquals(9001, PackagedClass.packagedMethod(9000));
    }
}

