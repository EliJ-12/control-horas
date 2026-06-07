import { useState } from "react";
import { useAutoTimeSettings, useSaveAutoTimeSettings, useUpdateAutoTimeSettings, useDeleteAutoTimeSettings } from "@/hooks/use-auto-time-settings";
import { useAuth } from "@/hooks/use-auth";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Clock, Settings, Save, Plus, Trash2, Edit2, ChevronDown, ChevronUp } from "lucide-react";
import { toast } from "@/hooks/use-toast";
import { type AutoTimeSettings } from "@shared/schema";

interface ConfigFormData {
  name: string;
  enabled: boolean;
  monday: boolean;
  tuesday: boolean;
  wednesday: boolean;
  thursday: boolean;
  friday: boolean;
  saturday: boolean;
  sunday: boolean;
  startTime: string;
  endTime: string;
  autoRegisterTime: string;
  priority: number;
}

const defaultFormData: ConfigFormData = {
  name: "Nueva configuración",
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
  autoRegisterTime: "17:05",
  priority: 0
};

export default function AutoTimeSettings() {
  console.log('AutoTimeSettings component rendering...');
  const { user } = useAuth();
  const { data: settings, isLoading, error } = useAutoTimeSettings();
  const saveSettings = useSaveAutoTimeSettings();
  const updateSettings = useUpdateAutoTimeSettings();
  const deleteSettings = useDeleteAutoTimeSettings();
  
  const [showNewForm, setShowNewForm] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [formData, setFormData] = useState<ConfigFormData>(defaultFormData);
  const [expandedIds, setExpandedIds] = useState<Set<number>>(new Set());

  const handleCreateNew = () => {
    setFormData(defaultFormData);
    setShowNewForm(true);
    setEditingId(null);
  };

  const handleEdit = (setting: AutoTimeSettings) => {
    setFormData({
      name: setting.name || "Configuración",
      enabled: setting.enabled || false,
      monday: setting.monday || false,
      tuesday: setting.tuesday || false,
      wednesday: setting.wednesday || false,
      thursday: setting.thursday || false,
      friday: setting.friday || false,
      saturday: setting.saturday || false,
      sunday: setting.sunday || false,
      startTime: setting.startTime,
      endTime: setting.endTime,
      autoRegisterTime: setting.autoRegisterTime,
      priority: setting.priority || 0
    });
    setEditingId(setting.id);
    setShowNewForm(true);
  };

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
      .filter(key => ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].includes(key))
      .some(key => formData[key as keyof ConfigFormData] as boolean);

    if (!hasSelectedDay) {
      toast({
        title: "Días Requeridos",
        description: "Selecciona al menos un día de la semana para el registro automático.",
        variant: "destructive"
      });
      return;
    }

    if (editingId) {
      updateSettings.mutate({
        id: editingId,
        data: { ...formData, userId: user.id }
      });
    } else {
      saveSettings.mutate({
        ...formData,
        userId: user.id
      });
    }

    setShowNewForm(false);
    setEditingId(null);
  };

  const handleDelete = (id: number) => {
    if (confirm("¿Estás seguro de que quieres eliminar esta configuración?")) {
      deleteSettings.mutate(id);
    }
  };

  const toggleExpand = (id: number) => {
    setExpandedIds(prev => {
      const newSet = new Set(prev);
      if (newSet.has(id)) {
        newSet.delete(id);
      } else {
        newSet.add(id);
      }
      return newSet;
    });
  };

  const handleDayToggle = (day: keyof ConfigFormData) => {
    setFormData(prev => ({
      ...prev,
      [day]: !prev[day as keyof ConfigFormData]
    }));
  };

  const weekDays = [
    { key: 'monday' as keyof ConfigFormData, label: 'Lunes' },
    { key: 'tuesday' as keyof ConfigFormData, label: 'Martes' },
    { key: 'wednesday' as keyof ConfigFormData, label: 'Miércoles' },
    { key: 'thursday' as keyof ConfigFormData, label: 'Jueves' },
    { key: 'friday' as keyof ConfigFormData, label: 'Viernes' },
    { key: 'saturday' as keyof ConfigFormData, label: 'Sábado' },
    { key: 'sunday' as keyof ConfigFormData, label: 'Domingo' }
  ];

  const ConfigForm = ({ isEditing = false }: { isEditing?: boolean }) => (
    <Card className={isEditing ? "border-blue-500" : ""}>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Settings className="h-5 w-5" />
          {isEditing ? "Editar Configuración" : "Nueva Configuración"}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="name">Nombre de la configuración</Label>
          <Input
            id="name"
            value={formData.name}
            onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
            disabled={!!error}
            placeholder="Ej: Horario Lunes-Jueves"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="priority">Prioridad (mayor número = mayor prioridad)</Label>
          <Input
            id="priority"
            type="number"
            value={formData.priority}
            onChange={(e) => setFormData(prev => ({ ...prev, priority: parseInt(e.target.value) || 0 }))}
            disabled={!!error}
            min="0"
          />
        </div>

        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <Label>Activar registro automático</Label>
            <p className="text-sm text-gray-500">
              El sistema creará automáticamente registros de horas según esta configuración
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
                    a la hora especificada. Si hay múltiples configuraciones para el mismo día, 
                    se usará la de mayor prioridad.
                  </p>
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              <Button 
                onClick={handleSave} 
                disabled={saveSettings.isPending || updateSettings.isPending || !!error}
                className="flex-1"
              >
                {saveSettings.isPending || updateSettings.isPending ? (
                  <>Guardando...</>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    {isEditing ? "Actualizar" : "Guardar"}
                  </>
                )}
              </Button>
              <Button 
                variant="outline"
                onClick={() => {
                  setShowNewForm(false);
                  setEditingId(null);
                }}
              >
                Cancelar
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );

  const ConfigCard = ({ setting }: { setting: AutoTimeSettings }) => {
    const isExpanded = expandedIds.has(setting.id);
    const selectedDays = weekDays.filter(day => setting[day.key]).map(d => d.label);

    return (
      <Card className={setting.enabled ? "border-green-500" : ""}>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-lg">
              <Settings className="h-5 w-5" />
              {setting.name}
              {setting.enabled && <span className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded">Activa</span>}
            </CardTitle>
            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => toggleExpand(setting.id)}
              >
                {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleEdit(setting)}
              >
                <Edit2 className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleDelete(setting.id)}
              >
                <Trash2 className="h-4 w-4 text-red-500" />
              </Button>
            </div>
          </div>
        </CardHeader>
        {isExpanded && (
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-gray-500">Horario:</span>
                <span className="ml-2 font-medium">{setting.startTime} - {setting.endTime}</span>
              </div>
              <div>
                <span className="text-gray-500">Registro automático:</span>
                <span className="ml-2 font-medium">{setting.autoRegisterTime}</span>
              </div>
              <div>
                <span className="text-gray-500">Prioridad:</span>
                <span className="ml-2 font-medium">{setting.priority || 0}</span>
              </div>
              <div>
                <span className="text-gray-500">Días:</span>
                <span className="ml-2 font-medium">{selectedDays.join(", ") || "Ninguno"}</span>
              </div>
            </div>
          </CardContent>
        )}
      </Card>
    );
  };

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

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Registro Automático de Horas
          </CardTitle>
        </CardHeader>
        <CardContent>
          {error && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
              <div className="flex items-start gap-2">
                <Settings className="h-4 w-4 text-yellow-600 mt-0.5" />
                <div className="text-sm text-yellow-800">
                  <p className="font-medium mb-1">Sin conexión al servidor</p>
                  <p>
                    No se puede conectar al servidor para cargar/guardar la configuración. 
                    Por favor, contacta al administrador para configurar el servidor.
                  </p>
                </div>
              </div>
            </div>
          )}

          <Button 
            onClick={handleCreateNew}
            disabled={!!error}
            className="w-full"
          >
            <Plus className="h-4 w-4 mr-2" />
            Nueva Configuración
          </Button>
        </CardContent>
      </Card>

      {showNewForm && <ConfigForm isEditing={!!editingId} />}

      {settings && settings.length > 0 && (
        <div className="space-y-4">
          <h3 className="text-lg font-semibold">Configuraciones existentes</h3>
          {settings.map((setting) => (
            <ConfigCard key={setting.id} setting={setting} />
          ))}
        </div>
      )}

      {settings && settings.length === 0 && !showNewForm && (
        <Card>
          <CardContent className="py-8 text-center text-gray-500">
            <Settings className="h-12 w-12 mx-auto mb-4 text-gray-300" />
            <p>No tienes configuraciones de registro automático.</p>
            <p className="text-sm mt-2">Crea una nueva configuración para empezar.</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
