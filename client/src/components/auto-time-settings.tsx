import { useState } from "react";
import { useAutoTimeSettings, useSaveAutoTimeSettings } from "@/hooks/use-auto-time-settings";
import { useAuth } from "@/hooks/use-auth";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Clock, Settings, Save } from "lucide-react";
import { toast } from "@/hooks/use-toast";

export default function AutoTimeSettings() {
  console.log('AutoTimeSettings component rendering...');
  const { user } = useAuth();
  const { data: settings, isLoading, error } = useAutoTimeSettings();
  const saveSettings = useSaveAutoTimeSettings();
  
  const [formData, setFormData] = useState({
    enabled: false,
    monday: false,
    tuesday: false,
    wednesday: false,
    thursday: false,
    friday: false,
    saturday: false,
    sunday: false,
    startTime: "09:00",
    endTime: "17:00",
    autoRegisterTime: "17:05"
  });

  // Update form data when settings are loaded
  if (settings && !isLoading && !error && formData.enabled !== settings.enabled) {
    setFormData({
      enabled: settings.enabled || false,
      monday: settings.monday || false,
      tuesday: settings.tuesday || false,
      wednesday: settings.wednesday || false,
      thursday: settings.thursday || false,
      friday: settings.friday || false,
      saturday: settings.saturday || false,
      sunday: settings.sunday || false,
      startTime: settings.startTime,
      endTime: settings.endTime,
      autoRegisterTime: settings.autoRegisterTime
    });
  }

  const handleSave = () => {
    if (!user) {
      toast({
        title: "Error",
        description: "Usuario no autenticado",
        variant: "destructive"
      });
      return;
    }

    if (!formData.enabled) {
      toast({
        title: "Configuración Desactivada",
        description: "Activa la opción para guardar la configuración.",
        variant: "destructive"
      });
      return;
    }

    // Check if at least one day is selected
    const hasSelectedDay = Object.keys(formData)
      .filter(key => key !== 'enabled' && key !== 'startTime' && key !== 'endTime' && key !== 'autoRegisterTime')
      .some(key => formData[key as keyof typeof formData] as boolean);

    if (!hasSelectedDay) {
      toast({
        title: "Días Requeridos",
        description: "Selecciona al menos un día de la semana para el registro automático.",
        variant: "destructive"
      });
      return;
    }

    saveSettings.mutate({
      ...formData,
      userId: user.id
    });
  };

  const handleDayToggle = (day: keyof typeof formData) => {
    setFormData(prev => ({
      ...prev,
      [day]: !prev[day as keyof typeof prev]
    }));
  };

  const weekDays = [
    { key: 'monday' as keyof typeof formData, label: 'Lunes' },
    { key: 'tuesday' as keyof typeof formData, label: 'Martes' },
    { key: 'wednesday' as keyof typeof formData, label: 'Miércoles' },
    { key: 'thursday' as keyof typeof formData, label: 'Jueves' },
    { key: 'friday' as keyof typeof formData, label: 'Viernes' },
    { key: 'saturday' as keyof typeof formData, label: 'Sábado' },
    { key: 'sunday' as keyof typeof formData, label: 'Domingo' }
  ];

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Registro Automático de Horas
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-3/4 mb-4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Show component even if there's an error or no data
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Settings className="h-5 w-5" />
          Registro Automático de Horas
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {error && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex items-start gap-2">
              <Settings className="h-4 w-4 text-yellow-600 mt-0.5" />
              <div className="text-sm text-yellow-800">
                <p className="font-medium mb-1">Sin conexión al servidor</p>
                <p>
                  No se puede conectar al servidor para cargar/guardar la configuración. 
                  El componente se muestra en modo demostración. 
                  Por favor, contacta al administrador para configurar el servidor.
                </p>
              </div>
            </div>
          </div>
        )}
        
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <Label>Activar registro automático</Label>
            <p className="text-sm text-gray-500">
              El sistema creará automáticamente registros de horas según tu configuración
            </p>
          </div>
          <Switch
            checked={formData.enabled}
            onCheckedChange={(checked) => setFormData(prev => ({ ...prev, enabled: checked }))}
            disabled={!!error}
          />
        </div>

        {formData.enabled && (
          <>
            <div className="space-y-4">
              <Label className="text-base font-medium">Días de la semana</Label>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {weekDays.map((day) => (
                  <div key={day.key} className="flex items-center space-x-2">
                    <Switch
                      id={day.key}
                      checked={formData[day.key] as boolean}
                      onCheckedChange={() => handleDayToggle(day.key)}
                      disabled={!!error}
                    />
                    <Label htmlFor={day.key} className="text-sm">
                      {day.label}
                    </Label>
                  </div>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="startTime">Hora de inicio</Label>
                <Input
                  id="startTime"
                  type="time"
                  value={formData.startTime}
                  onChange={(e) => setFormData(prev => ({ ...prev, startTime: e.target.value }))}
                  disabled={!!error}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="endTime">Hora de fin</Label>
                <Input
                  id="endTime"
                  type="time"
                  value={formData.endTime}
                  onChange={(e) => setFormData(prev => ({ ...prev, endTime: e.target.value }))}
                  disabled={!!error}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="autoRegisterTime">Hora de registro automático</Label>
                <Input
                  id="autoRegisterTime"
                  type="time"
                  value={formData.autoRegisterTime}
                  onChange={(e) => setFormData(prev => ({ ...prev, autoRegisterTime: e.target.value }))}
                  disabled={!!error}
                />
              </div>
            </div>

            <div className="bg-blue-50 p-4 rounded-lg">
              <div className="flex items-start gap-2">
                <Clock className="h-4 w-4 text-blue-600 mt-0.5" />
                <div className="text-sm text-blue-800">
                  <p className="font-medium mb-1">¿Cómo funciona?</p>
                  <p>
                    El sistema creará automáticamente un registro de horas cada día seleccionado 
                    a la hora especificada. Por ejemplo, si configuras lunes a viernes de 9:00 a 14:00 
                    con registro automático a las 14:05, el sistema creará un registro diario 
                    de lunes a viernes a las 14:05 con esas horas.
                  </p>
                  <p className="mt-2">
                    Los registros creados automáticamente pueden ser modificados si necesitas 
                    hacer cambios posteriores.
                  </p>
                </div>
              </div>
            </div>

            <Button 
              onClick={handleSave} 
              disabled={saveSettings.isPending || !!error}
              className="w-full md:w-auto"
            >
              {saveSettings.isPending ? (
                <>Guardando...</>
              ) : (
                <>
                  <Save className="h-4 w-4 mr-2" />
                  Guardar Configuración
                </>
              )}
            </Button>
          </>
        )}
      </CardContent>
    </Card>
  );
}
